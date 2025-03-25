*===========================================================================================
*  Copyright (C) 2023-2025 Energy modelling lab (https://energymodellinglab.com/).
*                Kristoffer S. Andersen
*  This software is  open source: you can redistribute it and/or modify it
*  under the terms of the GNU General Public License v3.0 (see file NOTICE-GPLv3.txt).
*  For further information, visit: <https://www.gnu.org/licenses/gpl-3.0.html>.
*
*  This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
*  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*===========================================================================================

$title   TIMES default report (timesreport_default.gms) - Collects all relevant data from TIMES default into one parameter

*==== Purpose this scripts collect all TIMES model data and writes it into a pivot ready format using parameter with the following dimensions
**                         sectors      attribute commodity     regionfrom       year      Vintage info  currency
**                              \             \       |            |               |         /          /
** PARAMETER       TIMESReport(sector,topic,attr,prc,com,all_TS,regFrom,RegTo,milestonyr,vntg,unit,cur) "TIMES reporting parameter";
**                                      |         |        |               |                   |
**                                   topic     proces    timeslice       regionto             unit

$ontext
*Overview of code (13/03/2025)
*=== 0 Define setglobal so that the code can be called externally
*=== 1 Define sets and parameter for TIMES default reporting
*=== 2 Declare TIMES default sets, parameters, variables and equations
*=== 3 Define sets an parameters to import times solution
*=== 4 TEST: Basic check and export of dummies from model
*=== 5 General period and proces maps definitions
       TEST: to ensure that prc and com maps are unique (to avoid double counting)
*=== 6 Reporting TIMES default model results
*=== 7 TEST: SUMcheck to confirm that TIMESreport includes all data from gdx file
*=== 8 Expand TIMES report to include additional userdefined dimensions
       TEST: To make sure that the expanded TIMESreport has the same number of records
*=== 9 Write reporting to gdx and csv
$offtext

*$onUndef allows undefined symbols to be declared. Without it, GAMS would error immediately upon encountering an undefined symbol during compilation.


*============================================================================================
* 0 Define setglobal so that the code can be called externally
*============================================================================================

*Time lapse parameter
PARAMETER  elapsedTIME(*,*) "Time elapsed until Parameter used to check progress of code"
           countprc(*,*)    "Count number of processes by sector";

* Set whether to run reporting based on a TIMES default standalone (default) or this setglobal
* is a place holder for the situation where we want to use timesreport to link with another
* model
$SETGLOBAL  standalone      "yes"

$SETGLOBAL  modelname       "DemoS_012_timesreport"

* Set name of TIMES default standalone (this set is set directly from VEDA using $case_name)
$IF NOT '%TIMESscenario%' $SETGLOBAL TIMESscenario DemoS_012

* Set manual flag if TIMES is solution is from VEDA version 2.17 or above ("1") or below 2.17 ("0")
* Related to parameter naming convention used in VEDA
$IF NOT '%VEDAversion_217plus%' $SETGLOBAL VEDAversion_217plus  "1"

* If-statements are created to ensure that data is extracted from the correct GDX-file.
$IF not exist '%pathTIMES%'   $SETGLOBAL pathTIMES  "c:\VEDA\GAMS_WrkTIMES"

* If-statements are created to ensure that data is extracted from the correct GDX-file.
$IF not exist '%pathTIMESmodel%'   $SETGLOBAL pathTIMESmodel  "..\"

*============================================================================================
* 1 Define sets and parameter for TIMES default reporting
*============================================================================================

SET     sector          "Sector sets, used for TIMESReport";
SET     service         "Energy service sets, used for TIMESReport";
SET     subsector       "Subsector sets, used for TIMESReport";
SET     techgroup       "Technology sets, used for TIMESReport";
SET     capacityunit    "Capacity unit sets, used for TIMESreport"
SET     comgroup        "Commodity sets, used for TIMESReport";
SET     topic           "Reporting topics from TIMES default" /
        material        "Material input or output, kton"
        emission        "GHG and other emissions"
        savin_e         "Energy savings"
        energy          "Energy"
        final_e         "Final energy demand"
        gross_e         "Gross energy"
        service         "Energy service demand"
        costs           "Annual discounted cost"
        lumpsum         "Lumpsum investment and subsidies etc. within each period"
        capacity        "Capacity"
        prices          "Prices"
        revenue         "Revenue, e.g. from electricity trade"
        constra         "information on constraints"
        inputpar        "Model input parameters"
        dummy           "Dummy imports"
/;

SET     attr            "TIMES default attributes for reporting" /
        actc            "Activitiy cost"
        invc            "Investment cost including hurdle rate"
        inv_            "Investment cost excluding hurdle rate"
        invx            "Annual discounted investment taxes"
        invs            "Annual discounted investment subsidies"
        salv            "Salvage cost"
        fixc            "Fixed O&M cost"
        fixx            "Fixed O&M taxes"
        fixs            "Fixed O&M subsidies"
        floc            "Fuel cost"
        flox            "Fuel taxes"
        flos            "Fuel subsidies"
        floq            "Emission trading system"
        flor            "Revenue from fuel production"
        instcap         "new cacapcity installed in period"
        fout            "commodity output from process"
        f_in            "commodity input to process"
        levc            "levelized cost of energy including emission"
        mpri            "Market/shadow price of commodity balance"
        apri            "Average price"
        proj            "Energy service demand"
        ncap            "new capacity within period"
        cap_            "total capacity within period"
        mcon            "Market/shadow price of user constraint"
        actl            "Activity level particular relevant for storage technologies"
        objsal          "Objective function salvage cost"
        objfix          "Objective function fixed cost"
        objinv          "Objective function investment cost"
        objvar          "Objective function variable cost"
        objdam          "Objective function damage cost"
        yrfr            "Time slice fractions"
/;

SET     units_desc    "Units used for rapporting" /
        pj            "Petajoule"
        pja           "Petajoule annual (capacity)"
        npj           "Net peta joule"
        mkr_npj       "million kr per net peta joule"
        mkr_kton      "million kr per kton"
        mw           "Mega watt"
        kton          "Kilo ton"
        ktona         "Kilo ton annual (capacity)"
        kr_kwh        "Kroner per kilo watt hour"
        kr_gj         "Kroner per gigajoule"
        mkr           "Million kroner"
        km2           "Square kilometers"
        mvkm          "million vechicle kilometers"
        kv            "1000 vechicles"
        xhp           "number of heat pumps"
        xev           "number of electric vechicles"
        nkstock       "energy service from stock"
        kstock        "stock of appliance in 1000"
        mkr_kstock    "millio kroner per 1000 stock"
        shr           "share calculation used for RE share of sales gas"
/;


elapsedTIME("ante","01setTIMESreport") = TIMEelapsed;

*============================================================================================
* 2 Get Scenario descripton and solver stats (vtrun file and lst file)
*============================================================================================
* We add information on scenario description to a scalar to store it in the GDX file (this should be improved on way or the other)
** First information on scenario name and model description is taken from vtrun file
$call grep "Title" "%pathTIMES%\%TIMESscenario%\vtrun.cmd" >  %pathTIMESmodel%\TIMESreport\tempData\title.txt"

** Second we run a bat file which dynamically generates a gms files
$call  '%pathTIMESmodel%TIMESreport\bat-scripts\create_scen_desc_gms.bat';

** Third include the gams files which defines the scalar
$include '%pathTIMESmodel%TIMESreport\tempData\create_scen_desc_set.gms';

*Get information form lst file on model statistics and solve summary
$call grep  "MODEL STATISTICS" -H -A 21 "%pathTIMES%\%TIMESscenario%\%TIMESscenario%.lst"             > "%pathTIMESmodel%\TIMESreport\SolverStats\%TIMESscenario%_solver_stats.txt"
$call grep  "S O L V E      S U M M A R Y" -A 50 "%pathTIMES%\%TIMESscenario%\%TIMESscenario%.lst"    > "%pathTIMESmodel%\TIMESreport\SolverStats\%TIMESscenario%_solver_summary.txt"

alias(scen_desc,scen);

*============================================================================================
* 2 Declare TIMES default sets, parameters, variables and equations
*============================================================================================

* Sets to be loaded from TIMES immediately at compilation time
SETS
        in_out                    "TIMES in out set"                  / IN, OUT /
        prc                       "Processes included into model"
        prc_desc                  "Processes description"
        prc_grp                   "List of process groups"
        com                       "Commodities included into model"
        com_grp                   "Commodity groups"
        com_desc                  "Commodities description"
        all_reg                   "External + internal regions"
        reg(all_reg)              "Internal regions (DKE, DKW)"
        all_ts                    "All time slices (annual, season, weekly, daynite)"
        com_ts(reg,com,all_ts)    "Connection between process groups and processes in model"
        prc_map(reg,prc_grp,prc)  "Connection between process groups and processes in model"
        top(reg,prc,com,in_out)   "Topology showing whether commodities are in_out of different processes in model"
        inv                       "TIMES investment marker"           / INV /
        milestonyr                "Projection years for which model to be run"
        ncapr_items               "Levcost identifiers"               /LEVCOST/
        var_obj_items(attr)       "Objective function identifiers"    /OBJSAL,OBJFIX,OBJINV,OBJVAR,OBJDAM/
        eohyears                  "Each year from 1st NCAP_PASTI to last milestonyr"
        allyear                   "All modelling year 1980-2200"
        periodyr                  "Map between milestone year and all years"
        top_ire(all_reg,com,all_reg,com,prc)                   "Trade within area of study"
        prc_gmap(all_reg,prc,*)   "List of additional VEDA process group mappings used for reporting"
        com_gmap(reg,*,com)       "User groups of individual commodities"
        ie                        "Alias with IMP,EXP"
        units                     "All units",
        units_com(units)          "All commodity units"
        units_act(units)          "All activity units"
        units_cap(units)          "All capacity units"
        units_mony(units)         "All monetary units"
        com_unit(all_reg,com,units)   "Unit associated with each commodity"
        cur                       "Currency",
        g_rcur(all_reg,cur)       "main currency by region"
;


*Define alias as needed
ALIAS(INV, INVT);
ALIAS(prc,prcT);
ALIAS(com,comT,comTT,comI,comO);
ALIAS(reg,regT);
ALIAS(all_reg,all_regT,regto,regfrom);
ALIAS(all_ts,ts);
ALIAS(cur,curr);

*============================================================================================
* 2.1 Import set definition from TIMES default model run (note this is a precondition for importing results)
*============================================================================================
* Load basic sets from TIMES at compilation time
$onUndf
$gdxin "%pathTIMES%\%TIMESscenario%\GamsSave\%TIMESscenario%.gdx"
$load  prc prc_desc prc_grp com com_desc com_grp all_reg reg all_TS com_TS prc_Map top milestonyr periodyr eohyears allyear top_ire ie=impexp prc_gmap com_gmap units units_com units_act units_cap units_mony com_unit cur g_rcur
* Check if TIMESreport sets exists and load if found
$if gdxSetType sectorTIMESreport $loadM sector = sectorTIMESreport
$if gdxSetType subsectorTIMESreport $loadM subsector = subsectorTIMESreport
$if gdxSetType serviceTIMESreport $loadM service = serviceTIMESreport
$if gdxSetType techgroupTIMESreport $loadM techgroup = techgroupTIMESreport
$if gdxSetType capacityunitTIMESreport $loadM capacityunit = capacityunitTIMESreport
$if gdxSetType comgroupTIMESreport $loadM comgroup = comgroupTIMESreport
$gdxin
;

alias(units,unit);
elapsedTIME("ante","02setTIMESsolution") = TIMEelapsed;
*============================================================================================
* 3 Define sets an parameters to import times solution
*============================================================================================
SETS
*        year(milestonyr)        "year relevant for linking iterating with cge"
        loopyears(milestonyr)   "year relevant for linking iterating with cge"
        vntg                    "Vintage"                               /1980*2100/
        newcap                  "New capacitiy dimensions"              /INSTCAP, LUMPINV, LUMPIX, INVX+, INV+/
        bd                      "Bound in GAMS"                         /UP, LO, FX, L/
        auxiliary               "Auxiliary set, used if dim is empty"   /'-'/
        item                    "Var_cap information"
                                /       '0'     "Residual capacity"
                                        '¤'     "Retired capacity"
                                        '-'     "New capacity"/;


*Add elements to set (we make sure all sets include NA)
*Add feature to leave dimension blank, i.e. "NA", when information is not available.
$onMulti
set     sector       / SYS "Energy System",
		       DMZ "Dummy imports",
		       "NA" "not available"/;
set     subsector    / "NA" "not available"/;
set     service      / "NA" "not available"/;
set     techgroup    / "NA" "not available"/;
set     capacityunit / "NA" "not available"/;
set     comgroup     / "NA" "not available"/;
set     cur          / "NA" "not available"/;
set     units        / "NA" "not available"/;
set     prc          / "NA" "not available"/;
set     com          / "NA" "not available"/;
set     vntg         / "NA" "not available"/;
$offMulti

* Define years based on milestone model years in TIMES default
alias(milestonyr,year);

* Loopyears (relevant when linking with external model)
        loopyears(milestonyr) = YES;


SCALAR  timesErrorLevel         "TIMES error level from GAMS execution"           / 0 /
        g_dyear                 "Discount year";

PARAMETER
*Collect year values from times (filtering for milesonyr only - this might be a problem if you discount to a year outside the milestonyr definition)
        YEARVAL(milestonyr)                                "TIMES year values"
*Length of each period milestonyr
        periodlength(milestonyr)                           "Length of each period milestonyr"
*Total discounted system cost (NOTICE: that it is the parameter OBJZ.l that is used from the gdx-file)TIMES objective value";
        VAR_OBJ_L(all_reg,var_obj_items,cur)               "TIMES objective value"
*Projected annual demand given in region (r), specified year (datayear) for commodity (c)
        com_proj(all_reg,milestonyr,com)                   "TIMES energy service demand"
*Commodity consumption by Process given in region (r), vintage of process (v), modelled period (t), specific process (p), input flow of commodity (c) at certain timeslice (s)
        F_in(all_reg,vntg,milestonyr,prcT,comT,all_TS)     "TIMES energy inputs"
*Commodity Production by Process  given in region (r), vintage of process (v), modelled period (t), specific process (p), output flow of commodity (c) at certain timeslice (s)
        F_out(all_reg,vntg,milestonyr,prcT,comT,all_TS)    "TIMES energy outputs"
* Annual flow cost (undiscounted) given in region (r), vintage of process (v), modelled period (t), specific process (p) and associated commodity (c) (NOTICE: that a process can have multiple associated commodities and therefore multiple indicies for cst_floc)
        cst_floc(all_reg,vntg,milestonyr,prcT,comT)        "TIMES fuel costs"
*Annual flow taxes/subsidies (undiscounted) given in region (r), vintage of process (v), modelled period (t), specific process (p) and associated commodity (c) (NOTICE: taxes are seen as positive (+ increasing objective (OBJ) function) and subsidies as negative (- decreasing OBJ function))
        cst_flox(all_reg,vntg,milestonyr,prcT,comT)        "TIMES fuel taxes and subsidies"
*Annual aciticty cost (undiscounted) given in region (r), vintage of process (v), modelled period (t), specific process (p) and Additional indicator for start-up costs (uc_n)
        cst_actc(all_reg,vntg,milestonyr,prcT,*)           "TIMES aciticty cost"
        cst_salv(all_reg,milestonyr,prcT)                  "TIMES salvage costs"
*Annual fixed operating and maintenance costs (undiscounted) given in region (r), vintage of process (v), modelled period (t) and specific process (p)
        cst_fixc(all_reg,vntg,milestonyr,prcT)             "TIMES fixed O&M costs"
*Annual fixed taxes/subsidies (undiscounted) given in region (r), vintage of process (v), modelled period (t) and specific process (p)
        cst_fixx(all_reg,vntg,milestonyr,prcT)             "TIMES fixed O&N taxes"
*Annual investment costs (undiscounted)  given in region (r), vintage of process (v), modelled period (t), specific process (p) and additional indicator for ***** (uc_n)
        cst_invc(all_reg,vntg,milestonyr,prcT,invT)        "TIMES investment costs"
*Annual investment taxes/subsidies (undiscounted)  given in region (r), vintage of process (v), modelled period (t), specific process (p) and additional indicator for ***** (uc_n)
        cst_invx(all_reg,vntg,milestonyr,prcT,invT)        "TIMES investment taxes/subsidies"
*new capacity parameters related to installed capacity or lumpsum investment given in region (r), vintage of process (v), modelled period (t), specific process (p) and additional indicator to seperate the specific informations e.g. newly installed capacity, lumpsum investments etc.
        cap_new(all_reg,vntg,prcT,milestonyr,newcap)       "TIMES lump sum investment, costs and subsidies"
*Alot of information regarding technology investment, but is mainly used for its levelized cost. Is given by region (r), modelled period (t), specific process (p) and additional indicators, where the LEVCOST is of specific interest here, and the only one taken out.
        par_ncapr(all_reg, milestonyr, prcT, ncapr_items)  "TIMES levelised cost of energy"
        par_ncapr_(all_reg, milestonyr, prcT)              "TIMES levelised cost of energy, only levcost"
*Shadow price (undiscounted) of commodity balance - being a strict equality (AKA. Commodity Slack/Levels - Marginals) given in region (r), modelled period (t), of commodity (c) (e.g. increase of production or decrease of consumption)
        par_CombalEm(all_reg,milestonyr,com,all_TS)        "TIMES shadow price on commodity balance"
        var_comprd(all_reg,milestonyr,com,all_TS)          "TIMES commodity production"
        var_flo(all_reg,vntg,milestonyr,prc,com,all_TS)    "TIMES commodity flows"
*Reporting var_act_level to get TS activity level
        var_act_level(all_reg,vntg,milestonyr,prcT,all_TS)       "Overall activity of process (level)"
*New technology capacity given in region (r), modelled period (t) and for specific process (p) (Notice: that the specific perimiter extracted is the var_ncap.l, which is the level or the actual realized new capacity in the model)
        var_ncap(all_reg,milestonyr,prcT)                  "TIMES new capacity"
*Capacity of a technology given in region (r), modelled period (t) and for specific process (p)  (Notice: that the specific perimiter extracted is the var_cap.l, which is the level or the actual realized capacity in the model)
        var_cap(all_RegT,milestonyr,prcT)                   "TIMES total capacity"
*Residual capacity of past investments given in region (r), for modelled period (t), for specific process (p) with vintage (v)
        par_pasti(all_reg,milestonyr,prcT,item)            "TIMES pasti-capacitiy available in each period"
*Technology capacity given in region (r), in modelled period (t) for specific process (p)
        par_capl(all_reg,milestonyr,prcT)                  "TIMES non-pasti capacity available in each period"
*Information on import and export prices in selected currency
        ire_price(all_reg,milestonyr,prcT,com,all_TS,reg,ie,cur) "Exogenous price of import/export"
*Value flow by processes (i.e. f_in x combalem)
        val_flo(all_reg,vntg, milestonyr, prcT, com)       "Value flow by processes"
*Relationship between capacity and acticity in the model
        coef_af(all_reg,vntg,milestonyr, prcT,all_TS,bd)    "Capacity/Activity relationship (model input)"
*Primary commodity and activity unit
        prc_actunt(all_reg,prcT,com,units)                  "Primary commodity and activity unit"
* Time-slice fraction information
        G_YRFR(all_reg, all_TS)                             "Time-slice fraction information"
;

*Explanation of the different inputs from the above chosen gdx-file. This information can also be found on in the documentation "https://iea-etsap.org/docs/Documentation_for_the_TIMES_Model-Part-II.pdf"
*Notice: that all input sets of the below stated parameters should be filled out in a relatable set, which can either be translated in a script later or in the current file

*============================================================================================
* 3.1 Load results from TIMES default and do initial corrections to reduces size of data (execution time)
*============================================================================================
execute_load  "%pathTIMES%\%TIMESscenario%\GamsSave\%TIMESscenario%.gdx"         cst_actc, cst_floc, cst_flox, cst_fixc, cst_fixx, cst_invc, cst_invx, F_in, F_out, par_COMBALem,cap_new, com_proj, par_ncapr, val_flo, var_ncap=var_ncap.l, var_cap = var_cap.l, par_pasti, par_capl, ire_price, coef_af, VAR_OBJ_L=VAR_OBJ.l, G_YRFR,         prc_actunt, var_act_level = var_act.l, g_dyear,yearval, periodlength = d;


* Reset "EPS's" to zero to reduce data size and makes sure that output is always numerical
cst_actc(all_reg,vntg,milestonyr,prcT,auxiliary)$(cst_actc(all_reg,vntg,milestonyr,prcT,auxiliary) eq EPS)                    = 0;
cst_floc(all_reg,vntg,milestonyr,prcT,comT)$(cst_floc(all_reg,vntg,milestonyr,prcT,comT) eq EPS)                              = 0;
cst_flox(all_reg,vntg,milestonyr,prcT,comT)$(cst_flox(all_reg,vntg,milestonyr,prcT,comT) eq EPS)                              = 0;
cst_fixc(all_reg,vntg,milestonyr,prcT)$(cst_fixc(all_reg,vntg,milestonyr,prcT) eq EPS)                                        = 0;
cst_fixx(all_reg,vntg,milestonyr,prcT)$(cst_fixx(all_reg,vntg,milestonyr,prcT) eq EPS)                                        = 0;
cst_invc(all_reg,vntg,milestonyr,prcT,invT)$(cst_invc(all_reg,vntg,milestonyr,prcT,invT) eq EPS)                              = 0;
cst_invx(all_reg,vntg,milestonyr,prcT,invT)$(cst_invx(all_reg,vntg,milestonyr,prcT,invT) eq EPS)                              = 0;
F_in(all_reg,vntg,milestonyr,prcT,comT,all_TS)$(F_in(all_reg,vntg,milestonyr,prcT,comT,all_TS) eq EPS)                        = 0;
F_out(all_reg,vntg,milestonyr,prcT,comT,all_TS)$(F_out(all_reg,vntg,milestonyr,prcT,comT,all_TS) eq EPS)                      = 0;
par_CombalEm(all_reg,milestonyr,com,all_TS)$(par_CombalEm(all_reg,milestonyr,com,all_TS) eq EPS)                              = 0;
cap_new(all_reg,vntg,prcT,milestonyr,newcap)$(cap_new(all_reg,vntg,prcT,milestonyr,newcap) eq EPS)                            = 0;
com_proj(all_reg,milestonyr,com)$(com_proj(all_reg,milestonyr,com) eq EPS)                                                    = 0;
par_ncapr(all_reg, milestonyr, prcT, ncapr_items)$(par_ncapr(all_reg, milestonyr, prcT, ncapr_items) eq EPS)                  = 0;
var_ncap(all_reg,milestonyr,prcT)$(var_ncap(all_reg,milestonyr,prcT)  eq EPS)                                                 = 0;
var_cap(RegT,milestonyr,prcT)$(var_cap(RegT,milestonyr,prcT)    eq EPS)                                                       = 0;
var_act_level(all_reg,vntg,milestonyr,prcT,all_TS)$(var_act_level(all_reg,vntg,milestonyr,prcT,all_TS) eq EPS)                = 0;
par_pasti(all_reg,milestonyr,prcT,"0")$(par_pasti(all_reg,milestonyr,prcT,"0") eq EPS)                                        = 0;
par_pasti(all_reg,milestonyr,prcT,"¤")                                                                                        = 0;
par_capl(all_reg,milestonyr,prcT)$(par_capl(all_reg,milestonyr,prcT) eq EPS)                                                  = 0;
ire_price(all_reg,milestonyr,prcT,com,all_TS,reg,ie,cur)$(ire_price(all_reg,milestonyr,prcT,com,all_TS,reg,ie,cur) eq EPS)    = 0;
val_flo(all_reg,vntg,milestonyr,prcT,com)$(val_flo(all_reg,vntg,milestonyr,prcT,com) eq EPS)                                  = 0;
coef_af(all_reg,vntg,milestonyr, prcT,all_TS,bd)$(coef_af(all_reg,vntg,milestonyr, prcT,all_TS,bd) eq EPS)                    = 0;

elapsedTIME("ante","03importTIMESresults") = TIMEelapsed;

*============================================================================================;
* 4 Basic check for dummies in model
*============================================================================================

Parameter       timesDummies(all_reg,vntg,milestonyr,prcT,comT,all_TS)            "TIMES dummies - if any"
                timesDummiesFlag                                               "Flag if dummies are present";

SET                 prcDM(prc)                                                     "TIMES processes for dummy imports";

*Setting all processes to not be included into "dummy"-set, for then specifically picking them out by name, as can be seen below
prcDM(prc) = NO;
*Includning IMPDEMZ - a dummy process that can feed any demand
prcDM('IMPDEMZ') = YES;
*Includning IMPNRGZ - a dummy process that can create any energy related commodity
prcDM('IMPNRGZ') = YES;
*Includning IMPMATZ - a dummy process that can create any material related commodity
prcDM('IMPMATZ') = YES;

* clean-up previous times dummies file if file exist
*$call 'del %pathTIMESmodel%TIMESreport\GDX\*_TimesDummies.gdx*'

*Defining timesDummies parameter to extract which dummies are present in model
timesDummies(all_reg,vntg,year,prcDM,comT,all_TS) = F_out(all_reg,vntg,year,prcDM,comT,all_TS);
* Defining timesDummiesFlag, which is a parameter that flags out which years are affected by dummies - And also where they are affected the most.
timesDummiesFlag(year) = sum((all_reg,vntg,prcDM,comT,all_TS), timesDummies(all_reg,vntg,year,prcDM,comT,all_TS));

* Creating if-statement that creates a massage for the user - to see that dummies are present, these are also displayed in the lst-file running the current gms-file.
        IF(sum(year, timesDummiesFlag(year)) gt  0,
                DISPLAY  timesDummiesFlag,timesdummies;
                execute 'msg "%username%" /time:0 Dummies present in TIMES solution. For detailed information see:  %pathTIMESmodel%TIMESReport\TempData\TimesDummies_%TIMESscenario%.gdx';
* Write information related to dummies to a gdx-file in the temp-library
                execute_unload '%pathTIMESmodel%TIMESreport\tempData\%TIMESscenario%_TimesDummies.gdx',
                timesDummies;
        );


        IF(timesErrorLevel ne 0,
                DISPLAY  timesErrorLevel;
                execute 'msg "%username%" /time:0 TIMES ERROR SEE TIMES SOLVER STATUS';
        );

elapsedTIME("ante","04dummiesTIMES") = TIMEelapsed;

*============================================================================================
* 5 General process  maps definitions
*============================================================================================

*============================================================================================
* 5.1 Utilize existing commodity maps TIMES

set     topPC(prc,com,in_out)   "Map processes to their commodity input and output for the present TIMES default solution"
        comSrv(com)             "Map energy service demands in the TIMES default solution gdx-file"
        comNRG(com)             "Map fuel input in the TIMES default solution gdx-file"
        comENV(com)             "Map environmental emissions commodities"
        comETS(com)             "Map ETS commodities"
        comMAT(com)             "Map material variables like cement"
        comNRGtopic(com,topic)  "Map between fuel and topics (used for energy commodities)"
        prc_capunt(units,prc);


* map processed based on their commodity input and output
topPC(prc,com,in_out) = SUM(reg, top(reg,prc,com,in_out));
comSrv(com)       = YES$sum(reg, com_gmap(reg,"DEM",com));
comNRG(com)       = YES$sum(reg, com_gmap(reg,"NRG",com));
comENV(com)       = YES$sum(reg, com_gmap(reg,"ENV",com));
comMAT(com)       = YES$sum(reg, com_gmap(reg,"MAT",com));
comETS(com)       = NO;


*prc_capunt(units,prc) = YES$1$sum(reg, prc_gmap(reg,prc,units));
*prc_capunt("MW",prc)$(not 1$sum(units, prc_capunt(units,prc))) = YES;

*============================================================================================
* 5.2 Define termporay set used for reporting purposes
SET     tmp_prc(prc)            "temporary proces list"
        tmp_reg(all_regT)       "temporary list of regions"
        tmp_prctrd(prc)         "temporary trade proces list"
        tmp_prcsav(prc)         "temporary savings proces list"
        tmp_comNRGin(com)       "temporary list of energy inputs"
        tmp_comNRGout(com)      "temporary list of energy output"
        tmp_comEMISin(com)      "temporary list of emission input commodities"
        tmp_comEMISout(com)     "temporary list of emission output commodities"
        tmp_comMATin(com)       "temporary list of material input commodities"
        tmp_comMATout(com)      "temporary list of material output commodities"
        tmp_comSrvout(com)      "temporary list of energy services";
*============================================================================================
* 5.3 Define maps that reflect proces and commodity sets defined in TIMES using prc_gmap

SET map_prc_sector(prc,sector)             "TIMES map between processes and sectors used for TIMESreport",
    map_prc_subsector(prc,subsector)       "TIMES map between processes and subgroup used for TIMESreport",
    map_prc_techgroup(prc,techgroup)       "TIMES map between processes and techgroup used for TIMESreport",
    map_prc_service(prc,service)           "TIMES map between processes and service used for TIMESreport",
    map_prc_capacityunit(prc,unit)         "TIMES map between commodities and service used for TIMESreport",
    map_com_comgroup(com,comgroup)         "TIMES map between commodities and service used for TIMESreport";

* Define sector map
map_prc_sector(prc,sector)       = 1$sum((reg), prc_gmap(reg,prc,sector));
* Add dummy processes to sector DMZ
map_prc_sector(prc,"DMZ")        = 1$prcDM(prc);
* Add "NA" if prc is not part of any sector
map_prc_sector(prc,"NA")$(not sum((sector), map_prc_sector(prc,sector))) = YES;

* Define subsector map
map_prc_subsector(prc,subsector) = 1$sum((reg), prc_gmap(reg,prc,subsector));
* Add "NA" if prc is not part of any subsector map
map_prc_subsector(prc,"NA")$(not sum((subsector), map_prc_subsector(prc,subsector))) = YES;
* Define techgroup map
map_prc_techgroup(prc,techgroup) = 1$sum((reg), prc_gmap(reg,prc,techgroup));
* Add "NA" if prc is not part of any techgroup map
map_prc_techgroup(prc,"NA")$(not sum((techgroup), map_prc_techgroup(prc,techgroup))) = YES;
* Define energy service map
map_prc_service(prc,service)     = 1$sum((reg), prc_gmap(reg,prc,service));
* Add "NA" if prc is not part of any service map
map_prc_service(prc,"NA")$(not sum((service), map_prc_service(prc,service))) = YES;
* Define capacity unit map
map_prc_capacityunit(prc,unit) = 1$sum((reg), prc_gmap(reg,prc,unit));
* Add "NA" if prc is not part of any service map
map_prc_capacityunit(prc,"NA")$(not sum((unit), map_prc_capacityunit(prc,unit))) = YES;
* Define energy service map
map_com_comgroup(com,comgroup)     = 1$sum((reg), com_gmap(reg,comgroup,com));
* Add "NA" if prc is not part of any service map
map_com_comgroup(com,"NA")$(not sum((comgroup), map_com_comgroup(com,comgroup))) = YES;

elapsedTIME("ante","05TIMESreportmaps") = TIMEelapsed;

*============================================================================================
* 5.3 Define maps that reflect proces and commodity sets defined in TIMES using prc_gmap

PARAMETER TESTsector        "Test if prc is only member of one sector (passed if zero records)"
          TESTsubsector     "Test if prc is only member of one subsector (passed if zero records)"
          TESTtechgroup     "Test if prc is only member of one techgroup (passed if zero records)"
          TESTservice       "Test if prc is only member of one service (passed if zero records)"
          TESTcapacityunit  "Test if prc is only member of one capacity unit (passed if zero records)"
          TESTcomgroup      "Test if com is only member of one commodity group (passed if zero records)"
;

*Test if a proces is associated with more than one sector, subsector, techgroup or service
*if so abort as this will result in double counting
TESTsector(prc)$(sum(sector, 1$map_prc_sector(prc,sector)) gt 1) = sum(sector, 1$map_prc_sector(prc,sector));
TESTsubsector(prc)$(sum(subsector, 1$map_prc_subsector(prc,subsector)) gt 1) = sum(subsector, 1$map_prc_subsector(prc,subsector));
TESTtechgroup(prc)$(sum(techgroup, 1$map_prc_techgroup(prc,techgroup)) gt 1) = sum(techgroup, 1$map_prc_techgroup(prc,techgroup));
TESTservice(prc)$(sum(service,   1$map_prc_service(prc,service)) gt 1) = sum(service, 1$map_prc_service(prc,service));
TESTcapacityunit(prc)$(sum(unit,   1$map_prc_capacityunit(prc,unit)) gt 1) = sum(unit, 1$map_prc_capacityunit(prc,unit));
TESTcomgroup(com)$(sum(comgroup, 1$map_com_comgroup(com,comgroup)) gt 1) = sum(comgroup, 1$map_com_comgroup(com,comgroup));

display TESTsector,TESTsubsector,TESTtechgroup,TESTservice,TESTcapacityunit,TESTcomgroup;

IF(YES$card(TESTsector),
    display TESTsector;
    execute 'msg "%username%" /time:0 "ERROR: Some processes are mapped to multiple sectors. For detailed information see:  %pathTIMESmodel%TIMESReport\TempData\%TIMESscenario%_TIMESREPORT_ABORTED_DUE_TO_DUPLICATED_SETS.gdx';
);

IF(YES$card(TESTsubsector),
    display TESTsubsector;
    execute 'msg "%username%" /time:0 "ERROR: Some processes are mapped to multiple subsectors. For detailed information see:  %pathTIMESmodel%TIMESReport\TempData\%TIMESscenario%_TIMESREPORT_ABORTED_DUE_TO_DUPLICATED_SETS.gdx';
);

IF(YES$card(TESTtechgroup),
    display TESTtechgroup;
    execute 'msg "%username%" /time:0 "ERROR: Some processes are mapped to multiple techgroups. For detailed information see:  %pathTIMESmodel%TIMESReport\TempData\%TIMESscenario%_TIMESREPORT_ABORTED_DUE_TO_DUPLICATED_SETS.gdx';
);

IF(YES$card(TESTservice),
    display TESTservice;
    execute 'msg "%username%" /time:0 "ERROR: Some processes are mapped to multiple services. For detailed information see:  %pathTIMESmodel%TIMESReport\TempData\%TIMESscenario%_TIMESREPORT_ABORTED_DUE_TO_DUPLICATED_SETS.gdx';
);

IF(YES$card(TESTcapacityunit),
    display TESTcapacityunit;
    execute 'msg "%username%" /time:0 "ERROR: Some processes are mapped to multiple capacity units. For detailed information see:  %pathTIMESmodel%TIMESReport\TempData\%TIMESscenario%_TIMESREPORT_ABORTED_DUE_TO_DUPLICATED_SETS.gdx';
);

IF(YES$card(TESTcomgroup),
    display TESTcomgroup;
    execute 'msg "%username%" /time:0 "ERROR: Some commodity  are mapped to multiple commodities groups. For detailed information see:  %pathTIMESmodel%TIMESReport\TempData\%TIMESscenario%_TIMESREPORT_ABORTED_DUE_TO_DUPLICATED_SETS.gdx';    
);

* clean-up if previous version of  ABORT_DUE_TO_DUPLICATED_SETS.gdx exists
$call 'del %pathTIMESmodel%TIMESreport\tempData\*_TIMESREPORT_ABORTED_DUE_TO_DUPLICATED_SETS.gdx'

* In case of any across the different maps write ABORT_DUE_TO_DUPLICATED_SETS.gdx and Abort TIMESReport
IF(card(TESTsector) + card(TESTsubsector) + card(TESTservice) + card(TESTtechgroup) + card(TESTcapacityunit) + card(TESTcomgroup) > 0,
                execute_unload '%pathTIMESmodel%TIMESreport\tempData\%TIMESscenario%_TIMESREPORT_ABORTED_DUE_TO_DUPLICATED_SETS.gdx',
		map_prc_sector, map_prc_subsector,map_prc_techgroup,map_prc_service,map_prc_capacityunit,map_com_comgroup,
                TESTsector, TESTsubsector, TESTservice, TESTcapacityunit, TESTcomgroup	    
    ABORT "ERROR: One of more of the processes and commodities maps include dublicates."
    ;);


elapsedTIME("ante","05TestMaps") = TIMEelapsed;

*============================================================================================
* 6 Reporting TIMES default model results
*============================================================================================

PARAMETER ReportInclude(sector)     "Flag YES if sector is to be included in timesreport";

*Default is to include all sectors
ReportInclude(sector) = yes;

*Alternatively one can choose to exclude all sectors by default for troubleshooting purposes
ReportInclude(sector) = no;

*======Define TIMES default reporting parameter
*                                               commodity   regionfrom        Vintage info
*                                                  |          |                        /
PARAMETER       TIMESReport(scen,sector,topic,attr,prc,com,all_ts,regfrom,regto,year,vntg,unit,cur) "TIMES reporting parameter";
*                                              |                       |
*                                             proces                regionto

PARAMETER       TIMESReport_v2(scen,sector,subsector,service,techgroup,comgroup,topic,attr,prc,com,all_ts,regfrom,regto,year,vntg,unit,cur) "TIMES reporting parameter";

elapsedTIME("ante","06Report") = TIMEelapsed;

*============================================================================================
* 6.1 Reporting (energy system level)
*============================================================================================
*Reporting objective function at regional and obj_items level using information in yearval and g_dyear to set discount year
TIMESReport(scen,"SYS","costs",var_obj_items,"NA","NA","annual",all_reg,regT,milestonyr,"NA","NA",cur)$(yearval(milestonyr) = g_dyear) = VAR_OBJ_L(all_reg,var_obj_items,cur);

*We need to correct objsal (salvage cost) )which currently is represented as a positive number, however, we would like to interpret it as a negative number
TIMESReport(scen,"SYS","costs","objsal","NA","NA","annual",all_reg,all_reg,milestonyr,"NA","NA",cur)$(TIMESReport(scen,"SYS","costs","objsal","NA","NA","annual",all_reg,all_reg,milestonyr,"NA","NA",cur) > 0) = -1 * TIMESReport(scen,"SYS","costs","objsal","NA","NA","annual",all_reg,all_reg,milestonyr,"NA","NA",cur);

*Report time-slice definition as this might be usefull futhere ex post calculations
*TIMESReport(scen,"SYS","inputpar","yrfr","NA","NA",all_TS,all_regT,regT,milestonyr,"NA","NA","NA")$(yearval(milestonyr) = g_dyear) = G_YRFR(all_reg, all_TS);

elapsedTIME("report","SYS") = TIMEelapsed;

*============================================================================================
* 6.2 Reporting (looping over sectors)
*============================================================================================
*Only include sectors that are part of the times solution
ReportInclude(sector) = YES$sum(prc, map_prc_sector(prc,sector));

*Troubleshooting (for trouble shooting you may focus on one particular sector)
*ReportInclude(sector) = NO; ReportInclude("AGR") = YES;
display ReportInclude;

LOOP(sector$ReportInclude(sector),
        tmp_prc(prc)            = NO;
*       Define list of processes associated with sector (include dummy processes)
        tmp_prc(prc)            = 1$map_prc_sector(prc,sector);
*       Define list of input to processes
        tmp_comNRGin(comNRG)    = NO;
        tmp_comNRGin(comNRG)    = YES$sum(tmp_prc, topPC(tmp_prc,comNRG,"IN")) +
*       Add commodities associated with trade proceses
                                  YES$sum((tmp_prc,reg,all_reg), top_ire(reg,comNRG,all_reg,comNRG,tmp_prc));
*       Define list of output from processes other than energy service associated with sector
        tmp_comNRGout(comNRG)   = NO;
        tmp_comNRGout(comNRG)   = YES$sum(tmp_prc, topPC(tmp_prc,comNRG,"OUT")) +
*       Add commodities associated with trade proceses
                                  YES$sum((tmp_prc,reg,all_reg), top_ire(all_reg,comNRG,reg,comNRG,tmp_prc));
*       Define list of emission input associated with sector
        tmp_comEMISin(comENV)   = NO;
        tmp_comEMISin(comENV)   = YES$sum((tmp_prc,all_reg,all_regT), topPC(tmp_prc,comENV,"IN") + top_ire(all_reg,comENV,all_regT,comENV,tmp_prc));
*       Define list of emission output from proces
        tmp_comEMISout(comENV)  = NO;
        tmp_comEMISout(comENV)  = YES$sum((tmp_prc,all_reg,all_regT), topPC(tmp_prc,comENV,"OUT") + top_ire(all_reg,comENV,all_regT,comENV,tmp_prc));
*       Define list of material commodity output from proces
        tmp_comMATin(comMAT)    = NO;
        tmp_comMATin(comMAT)    = YES$sum((tmp_prc,all_reg,all_regT), topPC(tmp_prc,comMAT,"IN")  + top_ire(all_reg,comMAT,all_regT,comMAT,tmp_prc));
*       Define list of material commodity output from proces
        tmp_comMATout(comMAT)   = NO;
        tmp_comMATout(comMAT)   =  YES$sum((tmp_prc,all_reg,all_regT),topPC(tmp_prc,comMAT,"OUT") + top_ire(all_reg,comMAT,all_regT,comMAT,tmp_prc));
*       Define list of energy service output associated with sector
        tmp_comSrvout(comSrv)   = NO;
        tmp_comSrvout(comSrv)   = YES$sum(tmp_prc, topPC(tmp_prc,comSrv,"OUT"));
*       Select all energy saving processes producing energy services
        tmp_prcsav(prc)         = NO;
        tmp_prcsav(tmp_prc)     = YES$SUM(tmp_comSrvout,  1$topPC(tmp_prc,tmp_comSrvout,"OUT"))
                                - YES$SUM(tmp_comNRGin,   1$topPC(tmp_prc,tmp_comNRGin ,"IN"));
*       Define list of tmp_prc that are part of a trade relationship"
        tmp_prctrd(tmp_prc)  = NO;
        tmp_prctrd(tmp_prc)  = YES$sum((regFrom,tmp_comNRGin,regTo),top_ire(regFrom,tmp_comNRGin,regTo,tmp_comNRGin,tmp_prc));

*display tmp_prc, tmp_comNRGin, tmp_comNRGout, tmp_comEMISout, tmp_comEMISin, tmp_comMATin, tmp_comMATout, tmp_comSrvout;);
*$exit

*       Dummy output (output)
        TIMESReport(scen,sector,"dummy","fout",tmp_prc,com,all_TS,regT,regT,milestonyr,vntg,unit, "NA")$prcDM(tmp_prc)
        = F_out(regT,vntg,milestonyr,tmp_prc,com,all_TS)$(
         com_unit(regT,com,unit));

*       Dummy output (input)
        TIMESReport(scen,sector,"dummy","f_in",tmp_prc,com,all_TS,regT,regT,milestonyr,vntg,unit, "NA")$prcDM(tmp_prc)
        = F_in(regT,vntg,milestonyr,tmp_prc,com,all_TS)$(
         com_unit(regT,com,unit));

*       Energy service demand (output)
        TIMESReport(scen,sector,"service","fout",tmp_prc,tmp_comSrvout,all_TS,regT,regT,milestonyr,vntg,unit, "NA")$(not prcDM(tmp_prc))
        = F_out(regT,vntg,milestonyr,tmp_prc,tmp_comSrvout,all_TS)$(
         com_unit(regT,tmp_comSrvout,unit)
         );

*       Energy output
        TIMESReport(scen,sector,"energy","fout" ,tmp_prc,tmp_comNRGout,all_TS,regT,regT,milestonyr,vntg,unit,"NA")$(not prcDM(tmp_prc))
        = F_out(regT,vntg,milestonyr,tmp_prc,tmp_comNRGout,all_TS)$
            com_unit(regT,tmp_comNRGout,unit);

*       Trade energy (import: regTo)
        TIMESReport(scen,sector,"energy","fout" ,tmp_prc,tmp_comNRGout,all_TS,regFrom,regTo,milestonyr,vntg,unit,"NA")$(tmp_prctrd(tmp_prc) and not (not prcDM(tmp_prc)))
        = F_out(regTo,vntg,milestonyr,tmp_prc,tmp_comNRGout,all_TS)$(
                top_ire(regFrom,tmp_comNRGout,regTo,tmp_comNRGout,tmp_prc)
           and  com_unit(regTo,tmp_comNRGout,unit));

*       Material output
        TIMESReport(scen,sector,"material","fout" ,tmp_prc,tmp_comMATout,all_TS,regT,regT,milestonyr,vntg,unit,"NA")$(not prcDM(tmp_prc))
        = F_out(regT,vntg,milestonyr,tmp_prc,tmp_comMATout,all_TS)$(
               com_unit(regT,tmp_comMATout,unit));

*       Emission output
        TIMESReport(scen,sector,"emission","fout" ,tmp_prc,tmp_comEMISout,all_TS,regT,regT,milestonyr,vntg,unit,"NA")
        = F_out(regT,vntg,milestonyr,tmp_prc,tmp_comEMISout,all_TS)$(
        com_unit(regT,tmp_comEMISout,unit));

*       Energy input
        TIMESReport(scen,sector,"energy","f_in" ,tmp_prc,tmp_comNRGin,all_TS,regT,regT,milestonyr,vntg,unit,"NA")$(not prcDM(tmp_prc))
        = F_in(regT,vntg,milestonyr,tmp_prc,tmp_comNRGin,all_TS)$
          com_unit(regT,tmp_comNRGin,unit);

*       Trade energy (export: regFrom)
        TIMESReport(scen,sector,"energy","f_in" ,tmp_prc,tmp_comNRGin,all_TS,regFrom,regTo,milestonyr,vntg,unit,"NA")$(tmp_prctrd(tmp_prc) and not prcDM(tmp_prc))
        = F_in(regFrom,vntg,milestonyr,tmp_prc,tmp_comNRGin,all_TS)$(
                top_ire(regFrom,tmp_comNRGin,regTo,tmp_comNRGin,tmp_prc)
            and com_unit(regFrom,tmp_comNRGin,unit));

*       Material input
        TIMESReport(scen,sector,"material","f_in" ,tmp_prc,tmp_comMATin,all_TS,regT,regT,milestonyr,vntg,unit,"NA")$(not prcDM(tmp_prc))
        = F_in(regT,vntg,milestonyr,tmp_prc,tmp_comMATin,all_TS)$(
               com_unit(regT,tmp_comMATin,unit));

*       Emission input
        TIMESReport(scen,sector,"emission","f_in" ,tmp_prc,tmp_comEMISin,all_TS,regT,regT,milestonyr,vntg,unit,"NA")
        = F_in(regT,vntg,milestonyr,tmp_prc,tmp_comEMISin,all_TS)$(
        com_unit(regT,tmp_comEMISin,unit));

*       Revenue from process fuel output
        TIMESReport(scen,sector,"costs","flor" ,tmp_prc,tmp_comNRGout,"ANNUAL",regT,regT,milestonyr,vntg,"NA",cur)$(val_flo(regT,vntg,milestonyr,tmp_prc,tmp_comNRGout) lt 0)
        =  (val_flo(regT,vntg,milestonyr,tmp_prc,tmp_comNRGout))$(
           g_rcur(regT,cur));

*       Fuel cost
        TIMESReport(scen,sector,"costs","floc" ,tmp_prc,tmp_comNRGin,"ANNUAL",regT,regT,milestonyr,vntg,"NA",cur)$(val_flo(regT,vntg,milestonyr,tmp_prc,tmp_comNRGin) gt 0)
        =  (val_flo(regT,vntg,milestonyr,tmp_prc,tmp_comNRGin))$(
            g_rcur(regT,cur));

*       Fuel taxes
        TIMESReport(scen,sector,"costs","flox" ,tmp_prc,tmp_comNRGin,'ANNUAL',regT,regT,milestonyr,vntg,"NA",cur)$
        (cst_flox(regT,vntg,milestonyr,tmp_prc,tmp_comNRGin) ge 0)
       = cst_flox(regT,vntg,milestonyr,tmp_prc,tmp_comNRGin)$(
         g_rcur(regT,cur));

*       Emission taxes
        TIMESReport(scen,sector,"costs","flox" ,tmp_prc,tmp_comEMISout,'ANNUAL',regT,regT,milestonyr,vntg,"NA",cur)$
        (cst_flox(regT,vntg,milestonyr,tmp_prc,tmp_comEMISout) ge 0 and not comETS(tmp_comEMISout))
       = cst_flox(regT,vntg,milestonyr,tmp_prc,tmp_comEMISout)$(
           g_rcur(regT,cur));

*       Emission trading system (ETS)
        TIMESReport(scen,sector,"costs","floq" ,tmp_prc,tmp_comEMISout,'ANNUAL',regT,regT,milestonyr,vntg,"NA",cur)$
        (cst_flox(regT,vntg,milestonyr,tmp_prc,tmp_comEMISout) ge 0 and comETS(tmp_comEMISout))
       = cst_flox(regT,vntg,milestonyr,tmp_prc,tmp_comEMISout)$(
           g_rcur(regT,cur));

*       Fuel subsidies
        TIMESReport(scen,sector,"costs","flos" ,tmp_prc,tmp_comNRGin,"annual",regT,regT,milestonyr,vntg,"NA",cur)$
        (cst_flox(regT,vntg,milestonyr,tmp_prc,tmp_comNRGin) le 0)
        = cst_flox(regT,vntg,milestonyr,tmp_prc,tmp_comNRGin)$(
          g_rcur(regT,cur));


*       GHG mitigation subsidy
        TIMESReport(scen,sector,"costs","flos" ,tmp_prc,tmp_comEMISout,"annual",regT,regT,milestonyr,vntg,"NA",cur)$
        (cst_flox(regT,vntg,milestonyr,tmp_prc,tmp_comEMISout) le 0)
        = cst_flox(regT,vntg,milestonyr,tmp_prc,tmp_comEMISout)$(
          g_rcur(regT,cur));

*       Marginal time-slice price of commodity input (only relevant for commodities on ts level)
        TIMESReport(scen,sector,"prices","mpri","NA",tmp_comNRGin,all_ts,regT,regT,milestonyr,"NA",unit,cur)$(not par_combalem(regT,milestonyr,tmp_comNRGin,"annual"))
         = par_combalem(regT,milestonyr,tmp_comNRGin,all_ts)$(
            com_unit(regT,tmp_comNRGin,unit)
            and g_rcur(regT,cur));;

*= Annual price of commodity input (commmodity on annual level)
  TIMESReport(scen,sector,"prices","apri" ,"NA",tmp_comNRGin,"annual",regT,regT,milestonyr,"NA",unit,cur) =
                    par_CombalEm(regT,milestonyr,tmp_comNRGin,"annual")$(
             com_unit(regT,tmp_comNRGin,unit)
             and g_rcur(regT,cur));

*= Annual price of commodity input (commmodity on ts level - calculated weighted by using G_YRFR)
  TIMESReport(scen,sector,"prices","apri" ,"NA",tmp_comNRGin,"annual",regT,regT,milestonyr,"NA",unit,cur)$(not par_CombalEm(regT,milestonyr,tmp_comNRGin,"annual"))
        = sum(all_TS,  par_CombalEm(regT,milestonyr,tmp_comNRGin,all_TS) * G_YRFR(regT, all_TS))$(
            com_unit(regT,tmp_comNRGin,unit)
            and g_rcur(regT,cur));

*= Annual price of commodity out
  TIMESReport(scen,sector,"prices","apri" ,"NA",tmp_comNRGout,"annual",regT,regT,milestonyr,"NA",unit,cur)$(not par_CombalEm(regT,milestonyr,tmp_comNRGout,"annual"))
        = sum(all_TS,  par_CombalEm(regT,milestonyr,tmp_comNRGout,all_TS) * G_YRFR(regT, all_TS))$(
            com_unit(regT,tmp_comNRGout,unit)
            and g_rcur(regT,cur));

*       Activity level of proces (particular relevant for storage technologies)
        TIMESReport(scen,sector,"capacity","actl" ,tmp_prc,com,all_TS,regT,regT,milestonyr,vntg,unit,"NA")$(not tmp_prctrd(tmp_prc)) =
        var_act_level(regT,vntg,milestonyr,tmp_prc,all_ts)$(
            prc_actunt(regT,tmp_prc,com,unit));

*       Variable O&M cost
        TIMESReport(scen,sector,"costs","actc" ,tmp_prc,"NA","annual",regT,regT,milestonyr,vntg,"NA",cur)
        = cst_actc(regT,vntg,milestonyr,tmp_prc,"-")$(
          g_rcur(regT,cur));

*       Fixed O&M cost
        TIMESReport(scen,sector,"costs","fixc" ,tmp_prc,"NA","annual",regT,regT,milestonyr,vntg,"NA",cur)
        = cst_fixc(regT,vntg,milestonyr,tmp_prc)$(
        g_rcur(regT,cur));

*       Fixed O&M taxes
        TIMESReport(scen,sector,"costs","fixx" ,tmp_prc,"NA","annual",regT,regT,milestonyr,vntg,"NA",cur)$(cst_fixx(regT,vntg,milestonyr,tmp_prc) ge 0)
        = cst_fixx(regT,vntg,milestonyr,tmp_prc)$(
          g_rcur(regT,cur));

*       Fixed O&M subsidies
        TIMESReport(scen,sector,"costs","fixs" ,tmp_prc,"NA","annual",regT,regT,milestonyr,vntg,"NA",cur)$(cst_fixx(regT,vntg,milestonyr,tmp_prc) lt 0)
        = cst_fixx(regT,vntg,milestonyr,tmp_prc)$(
          g_rcur(regT,cur));

*       Discounted annual invesment cost
        TIMESReport(scen,sector,"costs","invc" ,tmp_prc,"NA","annual",regT,regT,milestonyr,vntg,"NA",cur)
        = cst_invc(regT,vntg,milestonyr,tmp_prc,"INV")$(
          g_rcur(regT,cur));

*       Discounted annual investment taxes
        TIMESReport(scen,sector,"costs","invx" ,tmp_prc,"NA","annual",regT,regT,milestonyr,vntg,"NA",cur)$(cst_invx(regT,vntg,milestonyr,tmp_prc,"INV") ge 0)
        = cst_invx(regT,vntg,milestonyr,tmp_prc,"INV")$(
          g_rcur(regT,cur));

*       Discounted annual investment subsidy
        TIMESReport(scen,sector,"costs","invx" ,tmp_prc,"NA","annual",regT,regT,milestonyr,vntg,"NA",cur)$(cst_invx(regT,vntg,milestonyr,tmp_prc,"INV") lt 0)
        = cst_invx(regT,vntg,milestonyr,tmp_prc,"INV")$(
         g_rcur(regT,cur));

*       Average annual lumpsum investment (excluding hurdle rate)
        TIMESReport(scen,sector,"lumpsum","inv_" ,tmp_prc,"NA","annual",regT,regT,milestonyr,vntg, "NA",cur)
        = (cap_new(regT,vntg,tmp_prc,milestonyr,"lumpinv") / periodlength(milestonyr))$(
           g_rcur(regT,cur));

*       Average annual lumpsum investment subsidy (including effect of hurdle rate)
        TIMESReport(scen,sector,"lumpsum","invx" ,tmp_prc,"NA","annual",regT,regT,milestonyr,vntg,"NA",cur)
        $((cap_new(regT,vntg,tmp_prc,milestonyr,"lumpix") + cap_new(regT,vntg,tmp_prc,milestonyr,"invx+")) ge 0)
        = ((cap_new(regT,vntg,tmp_prc,milestonyr,"lumpix") + cap_new(regT,vntg,tmp_prc,milestonyr,"invx+")) / periodlength(milestonyr))$(
          g_rcur(regT,cur));

*       Average annual lumpsum investment subsidy (including effect of hurdle rate)
        TIMESReport(scen,sector,"lumpsum","invs" ,tmp_prc,"NA","annual",regT,regT,milestonyr,vntg,"NA",cur)
        $((cap_new(regT,vntg,tmp_prc,milestonyr,"lumpix") + cap_new(regT,vntg,tmp_prc,milestonyr,"invx+")) lt 0)
        = ((cap_new(regT,vntg,tmp_prc,milestonyr,"lumpix") + cap_new(regT,vntg,tmp_prc,milestonyr,"invx+")) / periodlength(milestonyr))$(
          g_rcur(regT,cur));

**= Capacity section (unit varies and information is not directly availble in gdx - output from TIMES)

*       Capacity 
        TIMESReport(scen,sector,"capacity","cap_" ,tmp_prc,"NA","annual",regT,regT,milestonyr,"NA",unit,"NA")$(not tmp_prcsav(tmp_prc))
         =  (par_capl(regT,milestonyr,tmp_prc) + par_pasti(regT,milestonyr,tmp_prc,"0") + par_pasti(regT,milestonyr,tmp_prc,"¤"))$ (
             map_prc_capacityunit(tmp_prc,unit));
*
*       Capacity
*       TIMESReport(scen,sector,"capacity","cap_" ,tmp_prc,"NA","annual",regT,regT,milestonyr,"NA",unit,"NA")$(not tmp_prcsav(tmp_prc))
*        =  (var_cap(regT,milestonyr,tmp_prc))$(prc_capunt(unit,tmp_prc));

*       New capacity
        TIMESReport(scen,sector,"capacity","ncap" ,tmp_prc,"NA","annual",regT,regT,milestonyr,"NA",unit,"NA")$(not tmp_prcsav(tmp_prc))
        = var_ncap(regT,milestonyr,tmp_prc)$(
          map_prc_capacityunit(tmp_prc,unit));

*       Energy savings capacity
        TIMESReport(scen,sector,"capacity","cap_" ,tmp_prcsav,"NA","annual",regT,regT,milestonyr,"NA",unit,"NA")
        =  (par_capl(regT,milestonyr,tmp_prcsav) + par_pasti(regT,milestonyr,tmp_prcsav,"0")+ par_pasti(regT,milestonyr,tmp_prcsav,"¤"))$(
           map_prc_capacityunit(tmp_prcsav,unit));

*       New energy savings capacity
        TIMESReport(scen,sector,"capacity","ncap" ,tmp_prcsav,"NA","annual",regT,regT,milestonyr,"NA",unit,"NA")
        = var_ncap(regT,milestonyr,tmp_prcsav)$(
            map_prc_capacityunit(tmp_prcsav,unit));

*       Levelised cost of proces
        TIMESReport(scen,sector,"capacity","levc" ,tmp_prc,com,"annual",regT,regT,milestonyr,"NA",unit,cur)
        = par_ncapr(regT, milestonyr, tmp_prc, "LEVCOST")$(
            prc_actunt(regT,tmp_prc,com,unit)
            and g_rcur(regT,cur));

elapsedTIME("report",sector) = TIMEelapsed;
countprc("count",sector)     = card(tmp_prc);

);


*============================================================================================
* 7 Test section: Sum check to confirm that TIMES report includes all data (f_in and f_out)
*===========================================================================================
* Currently this section only compares F_IN and F_out  form the TIMES gdx file with the TIMESreport parameter
* Additional test should be included

PARAMETERS SumTEST(*,attr,milestonyr,com,prc)  "Sum check to ensure correspondance between TIMES gdx file and TIMESReport"
           SumCheck_(attr,milestonyr,com,prc)  "Check difference between TIMES gdx and TIMES report "
           tolerance                           "Define tolerance for sum chekcs"                           /1e-09/ ;

*Sum over data in TIMESgdx
SumTEST("TIMESgdx","F_in",milestonyr,com,prc)    = sum((all_reg,vntg,all_TS),F_in(all_reg,vntg,milestonyr,prc,com,all_TS));
SumTEST("TIMESreport","F_in",milestonyr,com,prc) = sum((scen,sector,topic,all_TS,all_reg,all_regT,vntg,unit,cur), TIMESReport(scen,sector,topic,"f_in",prc,com,all_TS,all_reg,all_regT,milestonyr,vntg,unit,cur));

SumTEST("TIMESgdx","Fout",milestonyr,com,prc)    = sum((all_reg,vntg,all_TS),F_out(all_reg,vntg,milestonyr,prc,com,all_TS));
SumTEST("TIMESreport","Fout",milestonyr,com,prc) = sum((scen,sector,topic,all_TS,all_reg,all_regT,vntg,unit,cur), TIMESReport(scen,sector,topic,"fout",prc,com,all_TS,all_reg,all_regT,milestonyr,vntg,unit,cur));

SumCheck_(attr,milestonyr,com,prc)$(ABS(SumTEST("TIMESreport",attr,milestonyr,com,prc) - SumTEST("TIMESgdx",attr,milestonyr,com,prc)) > tolerance ) = SumTEST("TIMESreport",attr,milestonyr,com,prc) - SumTEST("TIMESgdx",attr,milestonyr,com,prc);
display SumCheck_;

execute$(sum((attr,milestonyr,com,prc),ABS(SumCheck_(attr,milestonyr,com,prc))) > tolerance) 'msg "%username%" /time:0 Aborted due to difference between data in TIMES gdx and TIMES report script: & /UIzCheck/' ;
ABORT$(sum((attr,milestonyr,com,prc),ABS(SumCheck_(attr,milestonyr,com,prc))) > tolerance) "ERROR: Aborted due to difference between data in TIMES gdx and TIMES report script";

elapsedTIME("post","07TestResults") = TIMEelapsed;

*============================================================================================
* 8 expanding times report with additional dimensions
*============================================================================================

TIMESReport_v2(scen,sector,"NA","NA","NA","NA",topic,attr,prc,com,all_TS,all_reg,all_regT,milestonyr,vntg,unit,cur)=
        TIMESReport(scen,sector,topic,attr,prc,com,all_TS,all_reg,all_regT,milestonyr,vntg,unit,cur);

**       Expand TIMESreport
        TIMESReport_v2(scen,sector,subsector,service,techgroup,comgroup,topic,attr,prc,com,all_TS,all_reg,all_regT,milestonyr,vntg,unit,cur)=
        TIMESReport_v2(scen,sector,"NA",service,techgroup,comgroup,topic,attr,prc,com,all_TS,all_reg,all_regT,milestonyr,vntg,unit,cur)$(
            map_prc_subsector(prc,subsector));
elapsedTIME("post","08ExpandTIMESreport_subsector") = TIMEelapsed;

        TIMESReport_v2(scen,sector,subsector,service,techgroup,comgroup,topic,attr,prc,com,all_TS,all_reg,all_regT,milestonyr,vntg,unit,cur)=
        TIMESReport_v2(scen,sector,subsector,"NA"  ,techgroup,comgroup,topic,attr,prc,com,all_TS,all_reg,all_regT,milestonyr,vntg,unit,cur)$(
            map_prc_service(prc,service));
elapsedTIME("post","08ExpandTIMESreport_service") = TIMEelapsed;

        TIMESReport_v2(scen,sector,subsector,service,techgroup,comgroup,topic,attr,prc,com,all_TS,all_reg,all_regT,milestonyr,vntg,unit,cur)=
        TIMESReport_v2(scen,sector,subsector,service,"NA"    ,comgroup,topic,attr,prc,com,all_TS,all_reg,all_regT,milestonyr,vntg,unit,cur)$(
            map_prc_techgroup(prc,techgroup));
elapsedTIME("post","08ExpandTIMESreport_techgroup") = TIMEelapsed;

        TIMESReport_v2(scen,sector,subsector,service,techgroup,comgroup,topic,attr,prc,com,all_TS,all_reg,all_regT,milestonyr,vntg,unit,cur)=
        TIMESReport_v2(scen,sector,subsector,service,techgroup,"NA"   ,topic,attr,prc,com,all_TS,all_reg,all_regT,milestonyr,vntg,unit,cur)$(
                map_com_comgroup(com,comgroup));
elapsedTIME("post","08ExpandTIMESreport_comgroup") = TIMEelapsed;


*=== Write a test to check if the number of records in TIMESReport and TIMESReport_vs are the same

* Calculate number of records in each parameter
PARAMETER count_TIMESReport_expanded;
PARAMETER count_TIMESReport_original;

count_TIMESReport_expanded = SUM((scen,sector,subsector,service,techgroup,comgroup,topic,attr,prc,com,all_TS,all_reg,all_regT,milestonyr,vntg,unit,cur)$
    TIMESReport_v2(scen,sector,subsector,service,techgroup,comgroup,topic,attr,prc,com,all_TS,all_reg,all_regT,milestonyr,vntg,unit,cur), 1);

count_TIMESReport_original = SUM((scen,sector,topic,attr,prc,com,all_TS,all_reg,all_regT,milestonyr,vntg,unit,cur)$
    TIMESReport(scen,sector,topic,attr,prc,com,all_TS,all_reg,all_regT,milestonyr,vntg,unit,cur), 1);

* Display results
DISPLAY count_TIMESReport_original, count_TIMESReport_expanded;

* Optional: Add an abort if counts don't match
ABORT$( count_TIMESReport_original <> count_TIMESReport_expanded) "ERROR: Record counts do not match between TIMESReport and TIMESReport_v2! "

* Optional: Display percentage difference if they don't match
PARAMETER diff_percent;
diff_percent$(count_TIMESReport_original > 0) = 100 * (count_TIMESReport_expanded - count_TIMESReport_original) / count_TIMESReport_original;
DISPLAY$(count_TIMESReport_original <> count_TIMESReport_expanded) diff_percent;

*============================================================================================
* 9 Write reporting to gdx and csv
*============================================================================================

*Write timesreport gdx-file including set definitions
*execute_unload '%pathTIMESmodel%\timesreport\GDX\%TIMESscenario%_TIMESreport.gdx' TIMESReport_v2, TIMESReport, sector, topic, attr, prc, prc_desc, com, com_desc, all_TS,regT, milestonyr,unit,vntg, comSrv, G_YRFR, map_com_comgroup;

*Write timesreport gdx-file including set definitions
execute_unload '%pathTIMESmodel%\timesreport\GDX\%TIMESscenario%_TIMESreport.gdx'  TIMESReport_v2 = timesreport, scen_desc, sector = sector_desc, subsector = subsector_desc,techgroup = techgroup_desc, service = service_desc, comgroup = comgroup_desc, topic = topic_desc , attr = attr_desc, prc_desc, com_desc, G_YRFR = all_ts_data,all_reg, milestonyr = year,vntg, elapsedTIME,countprc, map_prc_sector, map_prc_subsector, map_prc_techgroup, map_prc_service, map_com_comgroup;

elapsedTIME("post","9gdxwrite") = TIMEelapsed;

*Merge existing gdx-files and create csv-file
execute '%pathTIMESmodel%\TIMESreport\bat-scripts\runMerge_GDX2CSV_TIMESreports.bat';


OPTIONS elapsedTIME:1:0:1
display elapsedTIME,countprc;


