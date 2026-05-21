#==============================================================================
# create_times_db_multiple_scenarios.R (with timesmodel, sow, and scen_desc support)
#==============================================================================
#
# DESCRIPTION:
#   This script imports multiple TIMES model GDX files into a local DuckDB database
#   for easier querying and analysis. It extracts both descriptive sets and the
#   main TIMES report data, organizes them into tables with proper relationships,
#   and provides testing functionality to verify the import process.
#
# UPDATED: Now includes support for timesmodel and sow dimensions in TIMESReport,
#          modelname set, all_ts_data parameter, and scen_desc relationships
#
# AUTHOR: Kristoffer Steen Andersen, Energy Modelling Lab
#
# DATE: 20/05 (Updated for timesmodel, sow dimensions and scen_desc support)
#
# USAGE:
#   1. Set the paths to your GDX files in the 'gdx_files' vector
#   2. Configure the database name and folder in the configuration section
#   3. Run the script to create and populate the database
#
# DEPENDENCIES:
#   Required packages: gamstransfer, dplyr, DBI, duckdb
#
# NOTES:
#   - This script handles multiple scenarios from different GDX files
#   - Each GDX file is identified by a unique file_id in the database
#   - TIMESReport now includes timesmodel (first dimension) and sow (third dimension)
#   - scen_desc table creates proper scenario description relationships
#   - modelname set creates scenario-timesmodel relationships
#   - all_ts_data parameter captures timeslice data
#==============================================================================

## Ensure required libraries are installed
if(!require("gamstransfer")) {
    install.packages('gamstransfer', repos="https://cran.rstudio.com/")
}
if(!require("dplyr")) {
    install.packages('dplyr', repos="https://cran.rstudio.com/")
}
if(!require("DBI")) {
    install.packages('jsonlite', repos="https://cran.rstudio.com/")
}
if(!require("duckdb")) {
    install.packages('readr', repos="https://cran.rstudio.com/")
}
if(!require("this.path")) {
    install.packages('this.path', repos="https://cran.rstudio.com/")
}

# Required packages
library(gamstransfer)  # For reading GDX files
library(dplyr)         # For data manipulation
library(DBI)           # For database interface
library(duckdb)        # For DuckDB connection and operations
library(this.path)     # Allows us to set currently library as working library

#==============================================================================
# CONFIGURATION
#==============================================================================

# Get the directory from the path of the current file.
cur_dir2 = dirname(this.path())

# Set the working directory.
setwd <- cur_dir2

# Database configuration
db_name <- paste0(format(Sys.Date(), "%y%m%d"), "_DemoS_012.duckdb")
db_folder <- "duckDB"  # Folder where database will be created
db_path <- file.path(cur_dir2,db_folder, db_name)  # Full path to database file

# Create database folder if it doesn't exist
if (!dir.exists(db_folder)) {
    dir.create(db_folder, recursive = TRUE)
    message(sprintf("Created database folder: %s", db_folder))
}

## By default we want to create a duckdb from all existing timesreport files in
## GDX library
gdx_files <- list.files(paste0(setwd,"/GDX/"),pattern=".gdx$")

#==============================================================================
# HELPER FUNCTIONS
#==============================================================================

#' Read a GDX set and convert it to a dataframe
#'
#' This function extracts set data from a GAMS container and formats it as a dataframe
#' with proper column names. It handles different set structures and adds scenario info.
#'
#' @param container A GAMS container object from gamstransfer
#' @param set_name The name of the set to extract
#' @param scen The scenario identifier to associate with this data
#' @param add_scen Whether to add scenario column (default TRUE for most sets)
#'
#' @return A dataframe containing the set data with scenario information
#'
#' @examples
#' # container <- Container$new("path/to/file.gdx")
#' # sector_data <- read_gdx_set(container, "sector_desc", "BASE")
read_gdx_set <- function(container, set_name, scen, add_scen = TRUE) {
    # Get the set data from the container using records
    set_data <- container[set_name]$records

    if (set_name %in% c("prc_desc", "com_desc")) {
        # For prc_desc and com_desc, ignore the first column (region) and remove duplicates
        df <- set_data[, -1] %>%  # Remove the first column
            distinct()           # Remove duplicates from dataframe
        colnames(df) <- c("id", "description")
    } else if (set_name == "scen_desc") {
        # For scen_desc, it typically has scenario and description columns
        if (ncol(set_data) == 1) {
            # Handle sets with only one column (no description)
            df <- data.frame(id = set_data[[1]], stringsAsFactors = FALSE)
        } else if (ncol(set_data) >= 2) {
            # Handle sets with id and description columns
            df <- data.frame(
                scen = set_data[[1]],
                description = set_data[[2]],
                stringsAsFactors = FALSE
            )
            add_scen <- FALSE  # Don't add scen again if it's already there
        }
    } else {
        # For other description sets
        if (ncol(set_data) == 1) {
            # Handle sets with only one column (no description)
            df <- data.frame(id = set_data[[1]], stringsAsFactors = FALSE)
        } else {
            # Handle sets with id and description columns
            df <- data.frame(
                id = set_data[[1]],
                description = set_data[[2]],
                stringsAsFactors = FALSE
            )
        }
    }

    # Add scenario information (if needed)
    if (add_scen && set_name != "scen_desc") {
        df$scen <- scen
    }

    return(df)
}

#' Read modelname set from GDX file
#'
#' This function extracts the modelname set that links scenarios to TIMES models.
#' The set has the structure: Set modelname(scen,timesmodel)
#'
#' @param container A GAMS container object from gamstransfer
#'
#' @return A dataframe with scen and timesmodel columns
#'
#' @examples
#' # container <- Container$new("path/to/file.gdx")
#' # modelname_data <- read_modelname_set(container)
read_modelname_set <- function(container) {
    tryCatch({
        # Get the modelname set data
        modelname_data <- container["modelname"]$records

        # The set should have columns: scen, timesmodel
        if (nrow(modelname_data) > 0) {
            # Rename columns to match expected names
            colnames(modelname_data) <- c("scen", "timesmodel")

            message(sprintf("Found %d scenario-model relationships", nrow(modelname_data)))
            return(modelname_data)
        } else {
            message("No modelname relationships found")
            return(data.frame(scen = character(0), timesmodel = character(0)))
        }
    }, error = function(e) {
        message(sprintf("Error reading modelname set: %s", e$message))
        return(data.frame(scen = character(0), timesmodel = character(0)))
    })
}

#' Safely remove an existing database file
#'
#' This function attempts to disconnect any existing connections to the database
#' and then remove the database file. It throws an error if the file cannot be removed.
#'
#' @param db_path Path to the database file
#'
#' @return None, but removes the database file if it exists
#'
#' @examples
#' # safe_remove_db("nameDB.duckdb")
safe_remove_db <- function(db_path) {
    # Try to disconnect any existing connections
    try({
        # Get all connections
        all_cons <- dbListConnections(duckdb::duckdb())
        # Disconnect each one
        for(con in all_cons) {
            dbDisconnect(con, shutdown = TRUE)
        }
    }, silent = TRUE)

    # Try to remove the file
    if (file.exists(db_path)) {
        try(file.remove(db_path), silent = TRUE)
        # If file still exists, throw error
        if (file.exists(db_path)) {
            stop("Could not remove existing database file. Please ensure no other processes are using it.")
        }
    }
}


#' Load multiple GDX files into a DuckDB database
#'
#' This is the main function that processes each GDX file, extracts the descriptive sets
#' and the TIMES report data, and loads them into the database with proper relationships.
#' Now also includes modelname set processing, all_ts_data parameter, and scen_desc handling.
#'
#' @param gdx_files A vector of paths to GDX files
#' @param db_path Path where the database should be created
#'
#' @return A connection to the created database
#'
#' @examples
#' # gdx_files <- c("file1.gdx", "file2.gdx")
#' # con <- load_gdx_files(gdx_files, "DemoS_012.duckdb")
load_gdx_files <- function(gdx_files, db_path) {
    # First, safely remove existing database
    safe_remove_db(db_path)

    # Create new database connection
    con <- dbConnect(duckdb(), db_path)

    # Create source_files table to track file origins
    dbExecute(con, "
    CREATE TABLE source_files (
      file_id INTEGER PRIMARY KEY,
      filename VARCHAR,
      load_timestamp TIMESTAMP
    )
  ")

    # Create scenario_model table for modelname relationships
    dbExecute(con, "
    CREATE TABLE scenario_model (
      scen VARCHAR,
      timesmodel VARCHAR,
      file_id INTEGER,
      PRIMARY KEY (scen, timesmodel),
      FOREIGN KEY (file_id) REFERENCES source_files(file_id)
    )
  ")

    # Process each GDX file
    for(file_id in seq_along(gdx_files)) {
        gdx_path <- gdx_files[file_id]

        tryCatch({
            message(sprintf("\nProcessing file %d of %d: %s",
                            file_id, length(gdx_files), basename(gdx_path)))

            # Read GDX file
            container <- Container$new(gdx_path)

            # Get scenario name from timesreport
            scen <- unique(container["timesreport"]$records$scen)[1]
            message(sprintf("Processing scenario: %s", scen))

            # Add file to source_files table
            dbExecute(con, sprintf("
        INSERT INTO source_files (file_id, filename, load_timestamp)
        VALUES (%d, '%s', '%s')",
                                   file_id,
                                   basename(gdx_path),
                                   format(Sys.time(), "%Y-%m-%d %H:%M:%S")
            ))

            # Get available symbols in the GDX file
            available_sets <- container$listSymbols()

            # Process modelname set if available
            if ("modelname" %in% available_sets) {
                message("Processing modelname set...")
                modelname_df <- read_modelname_set(container)

                if (nrow(modelname_df) > 0) {
                    # Add file_id to modelname data
                    modelname_df$file_id <- file_id

                    # Insert modelname relationships
                    for (i in 1:nrow(modelname_df)) {
                        dbExecute(con, sprintf("
                INSERT OR IGNORE INTO scenario_model (scen, timesmodel, file_id)
                VALUES ('%s', '%s', %d)",
                                               gsub("'", "''", modelname_df$scen[i]),
                                               gsub("'", "''", modelname_df$timesmodel[i]),
                                               file_id
                        ))
                    }
                    message(sprintf("Added %d scenario-model relationships", nrow(modelname_df)))
                }
            } else {
                message("No modelname set found in this file")
            }

            # Define description sets to process
            desc_sets <- c("sector_desc", "subsector_desc", "service_desc",
                           "techgroup_desc", "comgroup_desc", "topic_desc",
                           "prc_desc", "com_desc","attr_desc", "scen_desc")

            # Process each description set
            for (set_name in desc_sets) {
                if (set_name %in% available_sets) {
                    # Read the set data
                    df <- read_gdx_set(container, set_name, scen)

                    if (set_name == "scen_desc") {
                        # Special handling for scen_desc - it's a global dimension, not per-scenario
                        if (!dbExistsTable(con, set_name)) {
                            # Create table for scenario descriptions
                            dbExecute(con, sprintf("
              CREATE TABLE %s (
                scen VARCHAR PRIMARY KEY,
                description VARCHAR
              )", set_name))
                        }

                        # Insert scen descriptions, ignore duplicates
                        if (nrow(df) > 0) {
                            dbExecute(con, sprintf("
            INSERT OR IGNORE INTO %s (scen, description)
            VALUES %s",
                                                   set_name,
                                                   paste(sprintf("('%s', '%s')",
                                                                 gsub("'", "''", df$scen),
                                                                 gsub("'", "''", df$description)),
                                                         collapse = ",")
                            ))
                            message(sprintf("Updated table %s", set_name))
                        }
                    } else {
                        # Create table if it doesn't exist
                        if (!dbExistsTable(con, set_name)) {
                            # Create table with scenario column
                            dbExecute(con, sprintf("
              CREATE TABLE %s (
                id VARCHAR,
                description VARCHAR,
                scen VARCHAR,
                PRIMARY KEY (id, scen)
              )", set_name))
                        }

                        # Insert new data, ignore duplicates
                        if (nrow(df) > 0) {
                            dbExecute(con, sprintf("
            INSERT OR IGNORE INTO %s (id, description, scen)
            VALUES %s",
                                                   set_name,
                                                   paste(sprintf("('%s', '%s', '%s')",
                                                                 gsub("'", "''", df$id),
                                                                 gsub("'", "''", df$description),
                                                                 gsub("'", "''", df$scen)),
                                                         collapse = ",")
                            ))

                            message(sprintf("Updated table %s for scenario %s", set_name, scen))
                        }
                    }
                }
            }

            # Read and process timesreport data (main facts table)
            # NOTE: TIMESReport now has dimensions:
            # (timesmodel, scen, sow, sector, subsector, service, techgroup, comgroup, topic, attr, prc, com, all_ts, regfrom, regto, year, vntg, unit, cur)
            if ("timesreport" %in% available_sets) {
                message("Reading timesreport data...")
                times_data <- container["timesreport"]$records

                # Add file_id to track source
                times_data$file_id <- file_id

                # Create timesreport table if it doesn't exist
                if (!dbExistsTable(con, "timesreport")) {
                    dbExecute(con, "
            CREATE TABLE timesreport (
              timesmodel VARCHAR,
              scen VARCHAR,
              sow VARCHAR,
              sector VARCHAR,
              subsector VARCHAR,
              service VARCHAR,
              techgroup VARCHAR,
              comgroup VARCHAR,
              topic VARCHAR,
              attr VARCHAR,
              prc VARCHAR,
              com VARCHAR,
              all_ts VARCHAR,
              regfrom VARCHAR,
              regto VARCHAR,
              year VARCHAR,
              vntg VARCHAR,
              unit VARCHAR,
              cur VARCHAR,
              value DOUBLE,
              file_id INTEGER,
              FOREIGN KEY (file_id) REFERENCES source_files(file_id),
              FOREIGN KEY (scen) REFERENCES scen_desc(scen)
            )
          ")
                }

                # Write the data to the facts table
                dbAppendTable(con, "timesreport", times_data)
                message(sprintf("Added %d rows to timesreport", nrow(times_data)))
            }

            # Read and process all_ts_data parameter
            if ("all_ts_data" %in% available_sets) {
                message("Reading all_ts_data parameter...")
                all_ts_data <- container["all_ts_data"]$records

                # Add file_id to track source
                all_ts_data$file_id <- file_id

                # Create all_ts_data table if it doesn't exist
                if (!dbExistsTable(con, "all_ts_data")) {
                    dbExecute(con, "
            CREATE TABLE all_ts_data (
              timesmodel VARCHAR,
              scen VARCHAR,
              all_reg VARCHAR,
              all_ts VARCHAR,
              value DOUBLE,
              file_id INTEGER,
              FOREIGN KEY (file_id) REFERENCES source_files(file_id)
            )
          ")
                }

                # Write the data to the all_ts_data table
                dbAppendTable(con, "all_ts_data", all_ts_data)
                message(sprintf("Added %d rows to all_ts_data", nrow(all_ts_data)))
            }

        }, error = function(e) {
            # Error handling
            message(sprintf("Error processing file %s: %s", basename(gdx_path), e$message))
        })
    }

    return(con)
}

#' Test the database after creation
#'
#' This function tests the created database by running sample queries
#' to verify that data was imported correctly and relationships work.
#' Now includes tests for scen_desc, timesmodel, and sow functionality.
#'
#' @param gdx_files A vector of paths to GDX files
#' @param db_path Path to the database file (optional, uses configured path if not provided)
#'
#' @return None, but prints test results
#'
#' @examples
#' # test_database(gdx_files, "times_db.duckdb")
test_database <- function(gdx_files, db_path = NULL) {
    # Use configured db_path if not provided
    # browser()
    if (is.null(db_path)) {
        db_path <- file.path(db_folder, db_name)
    }

    tryCatch({
        message("Creating new database...")
        con <- load_gdx_files(paste0("GDX/",gdx_files), db_path)

        # Test queries
        message("\nTesting database contents:")

        # Test 1: Check table counts
        tables <- dbListTables(con)
        message("\nTables in database:")
        for (table in tables) {
            count <- dbGetQuery(con, sprintf("SELECT COUNT(*) as count FROM %s", table))
            message(sprintf("%s: %d rows", table, count$count))
        }

        # Test 2: Sample from timesreport with file source
        message("\nSample from timesreport with file source:")
        sample_data <- dbGetQuery(con, "
      SELECT f.timesmodel, f.scen, f.sow, f.sector, f.value, sf.filename
      FROM timesreport f
      JOIN source_files sf ON f.file_id = sf.file_id
      WHERE value IS NOT NULL
      LIMIT 5
    ")
        print(sample_data)

        # Test 3: Sample join with sector descriptions
        message("\nSample join with sector descriptions:")
        join_test <- dbGetQuery(con, "
      SELECT DISTINCT f.sector, s.description, sf.filename, f.scen
      FROM timesreport f
      LEFT JOIN sector_desc s ON f.sector = s.id AND f.scen = s.scen
      JOIN source_files sf ON f.file_id = sf.file_id
      WHERE f.sector IS NOT NULL
      LIMIT 5
    ")
        print(join_test)

        # Test 4: Test scenario descriptions (scen_desc)
        message("\nScenario descriptions (scen_desc):")
        scen_test <- dbGetQuery(con, "
      SELECT DISTINCT scen, description
      FROM scen_desc
      ORDER BY scen
    ")
        if (nrow(scen_test) > 0) {
            print(scen_test)
        } else {
            message("No scenario descriptions found")
        }

        # Test 5: Test scenario-model relationships
        message("\nScenario-Model relationships:")
        model_test <- dbGetQuery(con, "
      SELECT sm.scen, sm.timesmodel, sf.filename
      FROM scenario_model sm
      JOIN source_files sf ON sm.file_id = sf.file_id
      ORDER BY sm.scen, sm.timesmodel
    ")
        if (nrow(model_test) > 0) {
            print(model_test)
        } else {
            message("No scenario-model relationships found")
        }

        # Test 6: Join timesreport with scenario descriptions
        message("\nSample join with scenario descriptions:")
        scen_join_test <- dbGetQuery(con, "
      SELECT DISTINCT f.timesmodel, f.scen, f.sow, sd.description as scen_desc, f.sector, sf.filename
      FROM timesreport f
      LEFT JOIN scen_desc sd ON f.scen = sd.scen
      JOIN source_files sf ON f.file_id = sf.file_id
      WHERE f.sector IS NOT NULL
      LIMIT 10
    ")
        print(scen_join_test)

        # Test 7: Test state-of-world (sow) values
        message("\nUnique state-of-world (sow) values:")
        sow_test <- dbGetQuery(con, "
      SELECT DISTINCT sow, COUNT(*) as count
      FROM timesreport
      GROUP BY sow
      ORDER BY sow
    ")
        if (nrow(sow_test) > 0) {
            print(sow_test)
        } else {
            message("No sow values found")
        }

        # Test 8: Test all_ts_data parameter
        message("\nSample from all_ts_data parameter:")
        all_ts_test <- dbGetQuery(con, "
      SELECT timesmodel, scen, all_reg, all_ts, value, sf.filename
      FROM all_ts_data a
      JOIN source_files sf ON a.file_id = sf.file_id
      WHERE value IS NOT NULL
      LIMIT 10
    ")
        if (nrow(all_ts_test) > 0) {
            print(all_ts_test)
        } else {
            message("No all_ts_data found")
        }

    }, finally = {
        # Ensure connection is closed properly
        if (exists("con") && !is.null(con)) {
            dbDisconnect(con, shutdown = TRUE)
        }
        message("\nTests completed!")
    })
}

#==============================================================================
# SCRIPT EXECUTION
#==============================================================================

# Note: Uncomment and modify these lines to use with specific files
# gdx_file <- "DemoS_012_TIMESreport.gdx"


# Display configuration
message(sprintf("Database will be created as: %s", db_path))
message(sprintf("Processing %d GDX files:", length(gdx_files)))
for (i in seq_along(gdx_files)) {
    message(sprintf("  %d. %s", i, gdx_files[i]))
}

# Execute the test function with the configured database path
test_database(gdx_files, db_path)
