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

* Set name name of TIMES scenario if this name does not already exist (the scenario name is defined automatically when runing TIMESreport from VEDA)
$IF NOT '%TIMESscenario%' $SETGLOBAL TIMESscenario DemoS_012

* Set GAMS_wrkTIMES library 
$SETGLOBAL GAMS_wrkTIMES "c:\VEDA\GAMS_WrkTIMES"

* Set path to vtrun.cmd file if this path does not already exist (the path is defined automatically when runing TIMESreport scenario file from VEDA).
$IF not exist '%pathGAMS_WrkTIMES_Model%'   $SETGLOBAL pathGAMS_WrkTIMES_Model  "%GAMS_wrkTIMES%\%TIMESscenario%"

* Set path to TIMES model if this path does not already exist (the path is defined automatically when runing TIMESreport scenario file from VEDA).
$IF not exist '%pathTIMESmodel%'   $SETGLOBAL pathTIMESmodel  "..\"


*============================================================================================
* 1 Define sets and parameter for TIMES default reporting
*============================================================================================

* Process group sets defined using VEDA 
SET     sector          "Sector group sets"
        subsector       "Subsector sets"
        service         "Energy service group sets"
        techgroup       "Technology group sets"
        capacityunit    "Capacity unit group sets";

* Commodity group sets defined in VEDA
SET     comgroup        "Commodity groupsets";

SET     topic           "Topics used for reporting" /
        material        "Material"
        emission        "Emission"
        energy          "Energy"
        demand          "Demand"
        acosts          "Undiscounted costs"
        dcosts          "Discounted costs"
        lumpsum         "Annual lumpsum costs"
        capacity        "Capacity"
        prices          "Prices"
        revenue         "Revenue"
        constraint      "Information on constraints"
        inputpar        "Model input parameters"
        dummy           "Dummy imports"
/;

SET     attr            "Attributes used for reporting" /
	actc            "Activitiy costs"
        invc            "Investment costs"
        inv_            "Investment costs excl. hurdle rate"
        invx            "Investment taxes"
        invs            "Investment subsidies"
        salv            "Salvage costs"
        fixc            "Fixed O&M costs"
        fixx            "Fixed O&M taxes"
        fixs            "Fixed O&M subsidies"
        decc            "Decommissioning costs"
        comc            "Commodity costs"
        comx            "Commodity taxes"
        coms            "Commodity subsides"
        comd            "Commodity damage costs"                 
        f_in            "Flow in"
        f_out           "Flow out"
        comnet          "Net commodity flow"
        floc            "Flow costs"
        flox            "Flow taxes"
        flos            "Flow subsidies"
        floq            "Flow ETS costs"
        flor            "Flow revenues"
        levc            "Levelized cost of energy"
        mpri            "Marginal price"
        apri            "Average price"
        proj            "Energy service demand"
        rcap            "Retired capacity"
        ncap            "New capacity"
        ecap            "Residual capacity"
        tcap            "Total capacity"             
        mcon            "Shadow price of user constraint"
        actl            "Activity levels"
        objsal          "Salvage costs"
        objfix          "Fixed costs"
        objinv          "Investment costs"
        objvar          "Variable cost"
        objdam          "Damage costs"
        yrfr            "Time slice fractions"
/;

elapsedTIME("ante","01setTIMESreport") = TIMEelapsed;

*============================================================================================
* 2 Get Scenario descripton and solver stats (vtrun file and lst file)
*============================================================================================
* We add information on scenario description to a scalar to store it in the GDX file (this should be improved on way or the other)
** First information on scenario name and model description is taken from vtrun file
$call grep "Title" "%pathGAMS_WrkTIMES_Model%\vtrun.cmd" >  %GAMS_WrkTIMES_Modelmodel%\TIMESreport\tempData\title.txt"

** Second we run a bat file which dynamically generates a gms files
$call  '%pathTIMESmodel%TIMESreport\bat-scripts\create_scen_desc_gms.bat';

** Third include the gams files which defines the scalar
$include '%pathTIMESmodel%TIMESreport\tempData\create_scen_desc_set.gms';

*Get information form lst file on model statistics and solve summary
$call grep  "MODEL STATISTICS" -H -A 21 "%pathGAMS_WrkTIMES_Model%\%TIMESscenario%.lst"             > "%pathTIMESmodel%\TIMESreport\SolverStats\%TIMESscenario%_solver_stats.txt"
$call grep  "S O L V E      S U M M A R Y" -A 50 "%pathGAMS_WrkTIMES_Model%\%TIMESscenario%.lst"    > "%pathTIMESmodel%\TIMESreport\SolverStats\%TIMESscenario%_solver_summary.txt"

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
$gdxin "%pathGAMS_WrkTIMES_Model%\GamsSave\%TIMESscenario%.gdx"
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
set     units_cap    / "NA" "not available"/;
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
	
*Total discounted system cost: variable representing objective function by region and main type (OBJINV, OBJFIX, OBJVAR, OBJSAL)
        VAR_OBJ_L(all_reg,var_obj_items,cur)               "TIMES objective value"

*Projected annual demand given in region (r), specified year (datayear) for commodity (c)
        com_proj(all_reg,milestonyr,com)                   "Demand projection"

*Commodity consumption by Process given in region (r), vintage of process (v), modelled period (t), specific process (p), input flow of commodity (c) at certain timeslice (s)
        F_in(all_reg,vntg,milestonyr,prcT,comT,all_TS)     "Flow inputs"
	
*Commodity Production by Process  given in region (r), vintage of process (v), modelled period (t), specific process (p), output flow of commodity (c) at certain timeslice (s)
        F_out(all_reg,vntg,milestonyr,prcT,comT,all_TS)    "Flow output"

*Annual undiscounted flow related costs (caused by FLO_COST, FLO_DELV, IRE_PRICE) in period (t)
*associated with a commodity (c) flow in/out of a process (p) with vintage period (v) as well as capacity
*related commodity flows (specified by NCAP_COM, NCAP_ICOM, NCAP_OCOM).
        cst_floc(all_reg,vntg,milestonyr,prcT,comT)        "Annual flow costs (including import/export prices)"
	
*Annual flow taxes/subsidies (undiscounted) given in region (r), vintage of process (v), modelled period (t), specific process (p) and associated commodity (c) (NOTICE: taxes are seen as positive (+ increasing objective (OBJ) function) and subsidies as negative (- decreasing OBJ function))
        cst_flox(all_reg,vntg,milestonyr,prcT,comT)        "Annual taxes and subsidies"

*Annual undiscounted costs for commodity (comT) (caused by COM_CSTNET and COM_CSTPRD) in period (t)
	cst_comc(all_reg, milestonyr,comT)                 "Annual commodity costs"

*Annual undiscounted taxes and subsidies for commodity (c) (caused by COM_TAXNET, COM_SUBNET,
*COM_TAXPRD, COM_SUBPRD) in period (t).
        cst_comx(all_reg,milestonyr,comT)                  "Annual commodity taxes/subsidies"

*Annual undiscounted commodity (c) related costs, caused by DAM_COST, in period (t)
	cst_dam(all_reg,milestonyr,comT)                   "Annual commodity damage cost"

*Annual undiscounted variable costs (caused by ACT_COST) in period (t) associated with the operation
*(activity) of a process (p) with vintage period (v). Additional indicator (uc_n) for start-up costs.
        cst_actc(all_reg,vntg,milestonyr,prcT,*)           "Annual commodity damage cost"

*Salvage value of investment cost, taxes and subsidies of process (p) with vintage period (v), for which the
*technical lifetime exceeds the end of the model horizon, value at year EOH+1.	
        cst_salv(all_reg,milestonyr,prcT)                  "Salvage values of capacities at EOH+1"

*Annual undiscounted fixed operating and maintenance costs (caused by NCAP_FOM) in period (t)
*associated with the installed capacity of process (p) with vintage period (v).	
        cst_fixc(all_reg,vntg,milestonyr,prcT)             "Annual fixed operating and maintenance costs"

*Annual undiscounted fixed operating and maintenance costs (caused by NCAP_FTAX, NCAP_FSUB) in
*period (t) associated with the installed capacity of process (p) with vintage period (v).
        cst_fixx(all_reg,vntg,milestonyr,prcT)             "Annual fixed taxes/subsidies"

*Annual undiscounted investment costs (caused by NCAP_COST) in period (t) spread over the economic
*lifetime (NCAP_ELIFE) of a process (p) with vintage period (v).	
        cst_invc(all_reg,vntg,milestonyr,prcT,invT)        "Annual investment costs"
	
*Annual undiscounted investment costs (caused by NCAP_ITAX, NCAP_ISUB) in period (t) spread over the
*economic lifetime (NCAP_ELIFE) of a process (p) with vintage period (v).
        cst_invx(all_reg,vntg,milestonyr,prcT,invT)        "Annual investment taxes/subsidies"
	
*Annual undiscounted decommissioning costs (caused by NCAP_DCOST and NCAP_DLAGC) in period (t),
*associated with the dismantling of process (p) with vintage period (v).
	cst_decc(all_reg,vntg,milestonyr,prcT)              "Annual decommissioning costs"
	
*Newly installed capacity and lumpsum investment by vintage and commissioning period:
*New capacity and lumpsum investment of process (p) of vintage (v) commissioned in period (t).
	cap_new(all_reg,vntg,prcT,milestonyr,newcap)       "TIMES lump sum investment, costs and subsidies"

*Alot of information regarding technology investment, but is mainly used for its levelized cost. Is given by region (r), modelled period (t), specific process (p) and additional indicators, where the LEVCOST is of specific interest here, and the only one taken out.
        par_ncapr(all_reg, milestonyr, prcT, ncapr_items)  "TIMES levelised cost of energy"
        par_ncapr_(all_reg, milestonyr, prcT)              "TIMES levelised cost of energy, only levcost"

*Undiscounted annual shadow price of commodity balance (EQE_COMBAL) being a strict equality. The
*marginal value describes the cost increase in the objective function, if the difference between production
*and consumption is increased by one unit. The marginal value can be determined by the production side
*(increasing production), but can also be set by the demand side (e.g., decrease of consumption by energy
*saving or substitution measures).
        par_CombalEm(all_reg,milestonyr,com,all_TS)        "Commodity Slack/Levels – Marginals"

*Level value of the commodity production variable (VAR_COMPRD). The variable represents the total
*production of a commodity. It is only reported, if a bound or cost is specified for it or it is used in a user
*constraint.
	var_comprd(all_reg,milestonyr,com,all_TS)          "Commodity Total Production"
*Flow of a commodity in or out of a process	
        var_flo(all_reg,vntg,milestonyr,prc,com,all_TS)    "Commodity flows"
    
*Net commodity level
        var_comnet_level(all_reg,milestonyr,com,all_TS)       "Net commodity production level (level)"
	
*Annual activity of a process
        var_act_level(all_reg,vntg,milestonyr,prcT,all_TS)       "Reporting var_act_level to get TS activity level (level)"
	
*New technology capacity given in region (r), modelled period (t) and for specific process (p) (Notice: that the specific perimiter extracted is the var_ncap.l, which is the level or the actual realized new capacity in the model)
        var_ncap(all_reg,milestonyr,prcT)                  "Investment (new capacity) in a process"

*Current capacity of a process, all vintages together
        var_cap(all_RegT,milestonyr,prcT)                   "Current capacity of a process, all vintages together"
	
*Residual capacity of past investments (NCAP_PASTI) of process (p) still existing in period (t), where
*vintage (v) is set to '0' to distinguish residual capacity from new capacity.
        par_pasti(all_reg,milestonyr,prcT,item)            "Technology Capacity"
	
*Capacity of process (p) in period (t), derived from VAR_NCAP in previous periods summed over all vintage
*periods. For still existing past investments, see PAR_PASTI.
        par_capl(all_reg,milestonyr,prcT)                  "Technology Capacity"
	
*Information on import and export prices in selected currency. IMPort/EXPort price (index ie) for to/from
*an internal region of a commodity (c) originating from/heading to an external region all_r.
	ire_price(all_reg,milestonyr,prcT,com,all_TS,all_regT,ie,cur) "Exogenous price of import/export"
	
*Flows of process (p) multiplied by the commodity balance marginals of those commodities (c) in period (t);
*the values can be interpreted as the market values of the process inputs and outputs.
        val_flo(all_reg,vntg, milestonyr, prcT, com)       "Annual commodity flow values"
	
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
execute_load  "%pathGAMS_WrkTIMES_Model%\GamsSave\%TIMESscenario%.gdx" cst_actc, cst_floc, cst_flox, cst_comx, cst_dam,cst_comc, cst_fixc, cst_fixx, cst_invc,cst_decc,cst_invx, F_in, F_out, par_COMBALem,cap_new, com_proj, par_ncapr, val_flo, var_ncap=var_ncap.l, var_cap = var_cap.l, par_pasti, par_capl, ire_price, coef_af, VAR_OBJ_L=VAR_OBJ.l, G_YRFR,         prc_actunt, var_comnet_level=var_comnet.l, var_act_level = var_act.l, g_dyear,yearval, periodlength = d;

* Reset "EPS's" to zero to reduce data size and makes sure that output is always numerical
cst_actc(all_reg,vntg,milestonyr,prcT,auxiliary)$(cst_actc(all_reg,vntg,milestonyr,prcT,auxiliary) eq EPS)                    = 0;
cst_floc(all_reg,vntg,milestonyr,prcT,comT)$(cst_floc(all_reg,vntg,milestonyr,prcT,comT) eq EPS)                              = 0;
cst_flox(all_reg,vntg,milestonyr,prcT,comT)$(cst_flox(all_reg,vntg,milestonyr,prcT,comT) eq EPS)                              = 0;
cst_comc(all_reg, milestonyr,comT)$(cst_comc(all_reg, milestonyr,comT) eq EPS)                                                = 0;
cst_comx(all_reg,milestonyr,comT)$(cst_comx(all_reg,milestonyr,comT) eq EPS)                                                  = 0;
cst_dam(all_reg,milestonyr,comT)$(cst_dam(all_reg,milestonyr,comT) eq EPS)                                                    = 0;
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
var_comnet_level(all_reg,milestonyr,com,all_TS)$(var_comnet_level(all_reg,milestonyr,com,all_TS) eq EPS)                      = 0;
var_act_level(all_reg,vntg,milestonyr,prcT,all_TS)$(var_act_level(all_reg,vntg,milestonyr,prcT,all_TS) eq EPS)                = 0;
par_pasti(all_reg,milestonyr,prcT,"0")$(par_pasti(all_reg,milestonyr,prcT,"0") eq EPS)                                        = 0;
par_pasti(all_reg,milestonyr,prcT,"¤")$(par_pasti(all_reg,milestonyr,prcT,"¤") eq EPS)                                      = 0;
par_capl(all_reg,milestonyr,prcT)$(par_capl(all_reg,milestonyr,prcT) eq EPS)                                                  = 0;
ire_price(all_reg,milestonyr,prcT,com,all_TS,reg,ie,cur)$(ire_price(all_reg,milestonyr,prcT,com,all_TS,reg,ie,cur) eq EPS)    = 0;
val_flo(all_reg,vntg,milestonyr,prcT,com)$(val_flo(all_reg,vntg,milestonyr,prcT,com) eq EPS)                                  = 0;
coef_af(all_reg,vntg,milestonyr, prcT,all_TS,bd)$(coef_af(all_reg,vntg,milestonyr, prcT,all_TS,bd) eq EPS)                    = 0;

elapsedTIME("ante","03importTIMESresults") = TIMEelapsed;

*============================================================================================;
* 4 Basic check for dummies in model
*============================================================================================

Parameter       timesDummies(attr,all_reg,vntg,milestonyr,prcT,comT,all_TS)            "TIMES dummies - if any"
                timesDummiesFlag                                               "Flag if dummies are present";

SET                 prcDMZ(prc)                                                     "TIMES processes for dummy imports";

*Setting all processes to not be included into "dummy"-set, for then specifically picking them out by name, as can be seen below
prcDMZ(prc) = NO;
*Includning IMPDEMZ - a dummy process that can feed any demand
prcDMZ('IMPDEMZ') = YES;
*Includning IMPNRGZ - a dummy process that can create any energy related commodity
prcDMZ('IMPNRGZ') = YES;
*Includning IMPMATZ - a dummy process that can create any material related commodity
prcDMZ('IMPMATZ') = YES;

* clean-up previous times dummies file if file exist
$call 'del %pathTIMESmodel%TIMESreport\GDX\*_TimesDummies.gdx*'

*Defining timesDummies parameter to extract which dummies are present in model
timesDummies("f_in",all_reg,vntg,year,prcDMZ,comT,all_TS) =    F_in(all_reg,vntg,year,prcDMZ,comT,all_TS);
timesDummies("f_out",all_reg,vntg,year,prcDMZ,comT,all_TS) =    F_out(all_reg,vntg,year,prcDMZ,comT,all_TS);
* Defining timesDummiesFlag, which is a parameter that flags out which years are affected by dummies - And also where they are affected the most.
timesDummiesFlag(year) = sum((attr,all_reg,vntg,prcDMZ,comT,all_TS), timesDummies(attr,all_reg,vntg,year,prcDMZ,comT,all_TS));

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
        comETS(*)             "Map ETS commodities"
        comMAT(com)             "Map material variables like cement"
        comNRGtopic(com,topic)  "Map between fuel and topics (used for energy commodities)"
        prc_capunt(units,prc);


* map processed based on their commodity input and output
topPC(prc,com,in_out) = SUM(reg, top(reg,prc,com,in_out));
comSrv(com)       = YES$sum(reg, com_gmap(reg,"DEM",com));
comNRG(com)       = YES$sum(reg, com_gmap(reg,"NRG",com));
comENV(com)       = YES$sum(reg, com_gmap(reg,"ENV",com));
comMAT(com)       = YES$sum(reg, com_gmap(reg,"MAT",com));
comETS("ETS1CO2") = YES;
comETS("ETS2CO2") = YES;

*============================================================================================
* 5.2 Define termporay set used for reporting purposes
SET     tmp_prc(prc)            "temporary proces list"
        tmp_reg(all_regT)       "temporary list of regions"
        tmp_prctrd(prc)         "temporary trade proces list"
        tmp_prcsts(prc)         "temporary storage proces list"
        tmp_comNRGin(com)       "temporary list of energy inputs"
        tmp_comNRGout(com)      "temporary list of energy output"
        tmp_comEMISin(com)      "temporary list of emission input commodities"
        tmp_comEMISout(com)     "temporary list of emission output commodities"
        tmp_comMATin(com)       "temporary list of material input commodities"
        tmp_comMATout(com)      "temporary list of material output commodities"
        tmp_comSrvout(com)      "temporary list of energy services";

alias(tmp_reg,tmp_regT);
*============================================================================================
* 5.3 Define maps that reflect proces and commodity sets defined in TIMES using prc_gmap

SET map_prc_sector(prc,sector)             "TIMES map between processes and sectors used for TIMESreport",
    map_prc_subsector(prc,subsector)       "TIMES map between processes and subgroup used for TIMESreport",
    map_prc_techgroup(prc,techgroup)       "TIMES map between processes and techgroup used for TIMESreport",
    map_prc_service(prc,service)           "TIMES map between processes and service used for TIMESreport",
    map_prc_capacityunit(prc,units_cap)    "TIMES map between commodities and service used for TIMESreport",
    map_com_comgroup(com,comgroup)         "TIMES map between commodities and service used for TIMESreport";

* Define sector map
map_prc_sector(prc,sector)       = 1$sum((reg), prc_gmap(reg,prc,sector));
* Add "NA" if prc is not a dummy proces and is not part of any sector
map_prc_sector(prc,"NA")$(not prcDMZ(prc) and not sum((sector), map_prc_sector(prc,sector))) = YES;
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
map_prc_capacityunit(prc,units_cap) = 1$sum((reg), prc_gmap(reg,prc,units_cap));
* Add "NA" if prc is not part of any service map
map_prc_capacityunit(prc,"NA")$(not sum((units_cap), map_prc_capacityunit(prc,units_cap))) = YES;
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
TESTcapacityunit(prc)$(sum(units_cap,   1$map_prc_capacityunit(prc,units_cap)) gt 1) = sum(units_cap, 1$map_prc_capacityunit(prc,units_cap));
TESTcomgroup(com)$(sum(comgroup, 1$map_com_comgroup(com,comgroup)) gt 1) = sum(comgroup, 1$map_com_comgroup(com,comgroup));

display TESTsector,TESTsubsector,TESTtechgroup,TESTservice,TESTcapacityunit,TESTcomgroup;

IF(YES$card(TESTsector),
    execute 'msg "%username%" /time:0 "ERROR: Some processes are mapped to multiple sectors. For detailed information see:  %pathTIMESmodel%TIMESReport\TempData\%TIMESscenario%_TIMESREPORT_ABORTED_DUE_TO_DUPLICATED_SETS.gdx';);

IF(YES$card(TESTsubsector),
    execute 'msg "%username%" /time:0 "ERROR: Some processes are mapped to multiple subsectors. For detailed information see:  %pathTIMESmodel%TIMESReport\TempData\%TIMESscenario%_TIMESREPORT_ABORTED_DUE_TO_DUPLICATED_SETS.gdx';);

IF(YES$card(TESTtechgroup),
    execute 'msg "%username%" /time:0 "ERROR: Some processes are mapped to multiple techgroups. For detailed information see:  %pathTIMESmodel%TIMESReport\TempData\%TIMESscenario%_TIMESREPORT_ABORTED_DUE_TO_DUPLICATED_SETS.gdx';);

IF(YES$card(TESTservice),
    execute 'msg "%username%" /time:0 "ERROR: Some processes are mapped to multiple services. For detailed information see:  %pathTIMESmodel%TIMESReport\TempData\%TIMESscenario%_TIMESREPORT_ABORTED_DUE_TO_DUPLICATED_SETS.gdx';);

IF(YES$card(TESTcapacityunit),
    execute 'msg "%username%" /time:0 "ERROR: Some processes are mapped to multiple capacity units. For detailed information see:  %pathTIMESmodel%TIMESReport\TempData\%TIMESscenario%_TIMESREPORT_ABORTED_DUE_TO_DUPLICATED_SETS.gdx';);

IF(YES$card(TESTcomgroup),
    execute 'msg "%username%" /time:0 "ERROR: Some commodity  are mapped to multiple commodities groups. For detailed information see:  %pathTIMESmodel%TIMESReport\TempData\%TIMESscenario%_TIMESREPORT_ABORTED_DUE_TO_DUPLICATED_SETS.gdx';);

* clean-up if previous version of  ABORT_DUE_TO_DUPLICATED_SETS.gdx exists
$call 'del %pathTIMESmodel%TIMESreport\tempData\*_TIMESREPORT_ABORTED_DUE_TO_DUPLICATED_SETS.gdx'

* In case of any across the different maps write ABORT_DUE_TO_DUPLICATED_SETS.gdx and Abort TIMESReport
IF(card(TESTsector) + card(TESTsubsector) + card(TESTservice) + card(TESTtechgroup) + card(TESTcapacityunit) + card(TESTcomgroup) > 0,
                execute_unload '%pathTIMESmodel%TIMESreport\tempData\%TIMESscenario%_TIMESREPORT_ABORTED_DUE_TO_DUPLICATED_SETS.gdx',
		map_prc_sector, map_prc_subsector,map_prc_techgroup,map_prc_service,map_prc_capacityunit,map_com_comgroup,
                TESTsector, TESTsubsector, TESTservice, TESTtechgroup, TESTcapacityunit, TESTcomgroup	    
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
TIMESReport(scen,"SYS","dcosts",var_obj_items,"NA","NA","annual",all_reg,all_reg,milestonyr,"NA","NA",cur)$(yearval(milestonyr) = g_dyear) = VAR_OBJ_L(all_reg,var_obj_items,cur);

*We need to correct objsal (salvage cost) )which currently is represented as a positive number, however, we would like to interpret it as a negative number
TIMESReport(scen,"SYS","dcosts","objsal","NA","NA","annual",all_reg,all_reg,milestonyr,"NA","NA",cur)$(TIMESReport(scen,"SYS","dcosts","objsal","NA","NA","annual",all_reg,all_reg,milestonyr,"NA","NA",cur) > 0) = -1 * TIMESReport(scen,"SYS","dcosts","objsal","NA","NA","annual",all_reg,all_reg,milestonyr,"NA","NA",cur);


* Commodity taxes (tracked on energy system level to avoid double counting)
TIMESReport(scen,"SYS","acosts","comx","NA",com,"annual",all_reg,all_reg,milestonyr,"NA","NA",cur)$ 
        (cst_comx(all_reg,milestonyr,com) ge 0)
       = cst_comx(all_reg,milestonyr,com)$(
         g_rcur(all_reg,cur));

* Commodity taxes (reported on system level since process information is not attached to this parameter)
TIMESReport(scen,"SYS","acosts","coms","NA",com,"annual",all_reg,all_reg,milestonyr,"NA","NA",cur)$ 
        (cst_comx(all_reg,milestonyr,com) lt 0)
       = cst_comx(all_reg,milestonyr,com)$(
         g_rcur(all_reg,cur));
 
* Annual undiscounted commodity related damage costs (reported on system level since process information is not attached to this parameter)
TIMESReport(scen,"SYS","acosts","comd","NA",com,"annual",all_reg,all_reg,milestonyr,"NA","NA",cur) 
       = cst_dam(all_reg,milestonyr,com)$(
         g_rcur(all_reg,cur));

* Annual undiscounted commodity related damage costs (reported on system level since process information is not attached to this parameter)
TIMESReport(scen,"SYS","acosts","comc","NA",com,"annual",all_reg,all_reg,milestonyr,"NA","NA",cur) 
       = cst_comc(all_reg,milestonyr,com)$(
         g_rcur(all_reg,cur));

* Annual undiscounted commodity related damage costs (reported on system level since process information is not attached to this parameter)
TIMESReport(scen,"SYS","emission","comnet","NA",comENV,all_TS,all_reg,all_reg,milestonyr,"NA",unit,"NA") 
       = var_comnet_level(all_reg,milestonyr,comENV,all_TS)$(
         com_unit(all_reg,comENV,unit));

elapsedTIME("report","SYS") = TIMEelapsed;

*============================================================================================
* 6.2 Reporting (model input reporting)
*============================================================================================

*       import price assumptions
        TIMESReport(scen,"SYS","inputpar","mpri",prc,com,all_TS,"IMPEXP",all_reg,milestonyr,"NA",unit, cur)
        = ire_price(all_reg,milestonyr,prc,com,all_TS,all_reg,"IMP",cur)$(
         com_unit(all_reg,com,unit));

*       export price assumptions
        TIMESReport(scen,"SYS","inputpar","mpri",prc,com,all_TS,all_reg,"IMPEXP",milestonyr,"NA",unit, cur)
        = ire_price(all_reg,milestonyr,prc,com,all_TS,all_reg,"EXP",cur)$(
         com_unit(all_reg,com,unit));
         
elapsedTIME("report","Input parameters") = TIMEelapsed;

*============================================================================================
* 6.3 Reporting (dummy reporting)
*============================================================================================

*       Dummy flow out 
        TIMESReport(scen,"DMZ","dummy","f_out",prcDMZ,com,all_TS,all_reg,all_reg,milestonyr,vntg,unit, "NA")
        = F_out(all_reg,vntg,milestonyr,prcDMZ,com,all_TS)$(
         com_unit(all_reg,com,unit));

*       Dummy flow in 
        TIMESReport(scen,"DMZ","dummy","f_in",prcDMZ,com,all_TS,all_reg,all_reg,milestonyr,vntg,unit, "NA")
        = F_in(all_reg,vntg,milestonyr,prcDMZ,com,all_TS)$(
         com_unit(all_reg,com,unit));

elapsedTIME("report","Dummies") = TIMEelapsed;


*============================================================================================
* 6.4 Reporting (loop sector reporting)
*============================================================================================

*Only include sectors that are part of the times solution
ReportInclude(sector) = YES$sum(prc, map_prc_sector(prc,sector));

*Troubleshooting (for trouble shooting you may focus on one particular sector)
*ReportInclude(sector) = NO; ReportInclude("NA") = YES;


LOOP(sector$ReportInclude(sector),
        tmp_prc(prc)            = NO;
*       Define list of processes associated with sector (include dummy processes)
        tmp_prc(prc)            = 1$map_prc_sector(prc,sector);
*       Define list of tmp_prc that are part of a trade relationship"
        tmp_prctrd(tmp_prc)     = NO;
        tmp_prctrd(tmp_prc)     = YES$sum((regFrom,com,regTo),top_ire(regFrom,com,regTo,com,tmp_prc));
*       Defines list of storage proces for which we want to report act.l
        tmp_prcsts(tmp_prc)     = NO;
	tmp_prcsts(tmp_prc)     = YES$sum(regT, prc_map(regT,"STS",tmp_prc));
*       Define list of regions relevant for sector
	tmp_reg(all_regT)       = NO;
	tmp_reg(all_regT)       = YES$sum(tmp_prc, prc_desc(all_regT,tmp_prc));
*       Define list of input to processes
        tmp_comNRGin(comNRG)    = NO;
        tmp_comNRGin(comNRG)    = YES$sum(tmp_prc, topPC(tmp_prc,comNRG,"IN")) +
*       Add commodities associated with trade proceses
                                  YES$sum((tmp_prctrd,reg,all_reg), top_ire(reg,comNRG,all_reg,comNRG,tmp_prctrd));
*       Define list of output from processes other than energy service associated with sector
        tmp_comNRGout(comNRG)   = NO;
        tmp_comNRGout(comNRG)   = YES$sum(tmp_prc, topPC(tmp_prc,comNRG,"OUT")) +
*       Add commodities associated with trade proceses
                                  YES$sum((tmp_prctrd,reg,all_reg), top_ire(all_reg,comNRG,reg,comNRG,tmp_prctrd));
*       Define list of emission input associated with sector (for now we assume that emission commodities trade is not modelled)
        tmp_comEMISin(comENV)   = NO;
        tmp_comEMISin(comENV)   = YES$sum((tmp_prc), topPC(tmp_prc,comENV,"IN")) +
*       Add commodities associated with trade proceses
                                  YES$sum((tmp_prctrd,reg,all_reg), top_ire(reg,comENV,all_reg,comENV,tmp_prctrd));
*       Define list of emission output from proces  (for now we assume that emission commodities trade is not modelled)
        tmp_comEMISout(comENV)  = NO;
        tmp_comEMISout(comENV)  = YES$sum((tmp_prc), topPC(tmp_prc,comENV,"OUT")) +
*       Add commodities associated with trade proceses
                                  YES$sum((tmp_prctrd,reg,all_reg), top_ire(all_reg,comENV,reg,comENV,tmp_prctrd));
*       Define list of material commodity output from proces  (for now we assume that material commodities trade is not modelled)
        tmp_comMATin(comMAT)    = NO;
        tmp_comMATin(comMAT)    = YES$sum((tmp_prc), topPC(tmp_prc,comMAT,"IN"));
*       Define list of material commodity output from proces (for now we assume that material commodities trade is not modelled)
        tmp_comMATout(comMAT)   = NO;
        tmp_comMATout(comMAT)   =  YES$sum((tmp_prc),topPC(tmp_prc,comMAT,"OUT"));
*       Define list of energy service output associated with sector
        tmp_comSrvout(comSrv)   = NO;
*       Add commodities associated with trade proceses
	tmp_comSrvout(comSrv)   = YES$sum(tmp_prc, topPC(tmp_prc,comSrv,"OUT")) +
*       Add commodities associated with trade proceses
 	                          YES$sum((tmp_prctrd,reg,all_reg), top_ire(all_reg,comSrv,reg,comSrv,tmp_prctrd));

*display tmp_reg, tmp_prc, tmp_prctrd,tmp_prcsts,tmp_comNRGin, tmp_comNRGout, tmp_comEMISout, tmp_comEMISin, tmp_comMATin, tmp_comMATout, tmp_comSrvout, elapsedTIME;);
*$exit
		 
*       Energy service demand (output)
        TIMESReport(scen,sector,"demand","f_out",tmp_prc,tmp_comSrvout,all_TS,tmp_reg,tmp_reg,milestonyr,vntg,unit, "NA")$(prc_desc(tmp_reg,tmp_prc)
                                                                                                                           and not prcDMZ(tmp_prc))
        = F_out(tmp_reg,vntg,milestonyr,tmp_prc,tmp_comSrvout,all_TS)$(
         com_unit(tmp_reg,tmp_comSrvout,unit)
         );

*       Energy input
        TIMESReport(scen,sector,"energy","f_in" ,tmp_prc,tmp_comNRGin,all_TS,tmp_reg,tmp_reg,milestonyr,vntg,unit,"NA")$(prc_desc(tmp_reg,tmp_prc)
                                                                                                                           and not prcDMZ(tmp_prc))
        = F_in(tmp_reg,vntg,milestonyr,tmp_prc,tmp_comNRGin,all_TS)$
          com_unit(tmp_reg,tmp_comNRGin,unit);

*       Energy output
        TIMESReport(scen,sector,"energy","f_out" ,tmp_prc,tmp_comNRGout,all_TS,tmp_reg,tmp_reg,milestonyr,vntg,unit,"NA")$(prc_desc(tmp_reg,tmp_prc)
                                                                                                                           and not prcDMZ(tmp_prc))
        = F_out(tmp_reg,vntg,milestonyr,tmp_prc,tmp_comNRGout,all_TS)$
            com_unit(tmp_reg,tmp_comNRGout,unit);

*       Trade energy (import: regTo)
        TIMESReport(scen,sector,"energy","f_out" ,tmp_prc,tmp_comNRGout,all_TS,regFrom,regTo,milestonyr,vntg,unit,"NA")$(tmp_prctrd(tmp_prc) and not prcDMZ(tmp_prc))
        = F_out(regTo,vntg,milestonyr,tmp_prc,tmp_comNRGout,all_TS)$(
                top_ire(regFrom,tmp_comNRGout,regTo,tmp_comNRGout,tmp_prc)
           and  com_unit(regTo,tmp_comNRGout,unit));

*       Trade energy (export: regFrom)
        TIMESReport(scen,sector,"energy","f_in" ,tmp_prc,tmp_comNRGin,all_TS,regFrom,regTo,milestonyr,vntg,unit,"NA")$(tmp_prctrd(tmp_prc) and not prcDMZ(tmp_prc))
        = F_in(regFrom,vntg,milestonyr,tmp_prc,tmp_comNRGin,all_TS)$(
                top_ire(regFrom,tmp_comNRGin,regTo,tmp_comNRGin,tmp_prc)
            and com_unit(regFrom,tmp_comNRGin,unit));  

*       Emission input
        TIMESReport(scen,sector,"emission","f_in" ,tmp_prc,tmp_comEMISin,all_TS,tmp_reg,tmp_reg,milestonyr,vntg,unit,"NA")$(prc_desc(tmp_reg,tmp_prc)
                                                                                                                           and not prcDMZ(tmp_prc))
        = F_in(tmp_reg,vntg,milestonyr,tmp_prc,tmp_comEMISin,all_TS)$(
        com_unit(tmp_reg,tmp_comEMISin,unit));

*       Emission output
        TIMESReport(scen,sector,"emission","f_out" ,tmp_prc,tmp_comEMISout,all_TS,tmp_reg,tmp_reg,milestonyr,vntg,unit,"NA")$(prc_desc(tmp_reg,tmp_prc)
                                                                                                                              and not prcDMZ(tmp_prc))
        = F_out(tmp_reg,vntg,milestonyr,tmp_prc,tmp_comEMISout,all_TS)$(
        com_unit(tmp_reg,tmp_comEMISout,unit));

*       Trade emission (import: regTo)
        TIMESReport(scen,sector,"emission","f_out" ,tmp_prc,tmp_comEMISout,all_TS,regFrom,regTo,milestonyr,vntg,unit,"NA")$(tmp_prctrd(tmp_prc) and not prcDMZ(tmp_prc))
        = F_out(regTo,vntg,milestonyr,tmp_prc,tmp_comEMISout,all_TS)$(
                top_ire(regFrom,tmp_comEMISout,regTo,tmp_comEMISout,tmp_prc)
           and  com_unit(regTo,tmp_comEMISout,unit));

*       Trade emission (export: regFrom)
        TIMESReport(scen,sector,"emission","f_in" ,tmp_prc,tmp_comEMISin,all_TS,regFrom,regTo,milestonyr,vntg,unit,"NA")$(tmp_prctrd(tmp_prc) and not prcDMZ(tmp_prc))
        = F_in(regFrom,vntg,milestonyr,tmp_prc,tmp_comEMISin,all_TS)$(
                top_ire(regFrom,tmp_comEMISin,regTo,tmp_comEMISin,tmp_prc)
            and com_unit(regFrom,tmp_comEMISin,unit));

*       Material input
        TIMESReport(scen,sector,"material","f_in" ,tmp_prc,tmp_comMATin,all_TS,tmp_reg,tmp_reg,milestonyr,vntg,unit,"NA")$(prc_desc(tmp_reg,tmp_prc)
                                                                                                                           and not prcDMZ(tmp_prc))
        = F_in(tmp_reg,vntg,milestonyr,tmp_prc,tmp_comMATin,all_TS)$(
               com_unit(tmp_reg,tmp_comMATin,unit));

*       Material output
        TIMESReport(scen,sector,"material","f_out" ,tmp_prc,tmp_comMATout,all_TS,tmp_reg,tmp_reg,milestonyr,vntg,unit,"NA")$(prc_desc(tmp_reg,tmp_prc)
                                                                                                                              and not prcDMZ(tmp_prc))
        = F_out(tmp_reg,vntg,milestonyr,tmp_prc,tmp_comMATout,all_TS)$(
               com_unit(tmp_reg,tmp_comMATout,unit));

*elapsedTIME("report","f_in_out") = TIMEelapsed;

*       Marginal time-slice price of commodity input (only relevant for commodities on ts level)
        TIMESReport(scen,sector,"prices","mpri","NA",tmp_comNRGin,all_ts,tmp_reg,tmp_reg,milestonyr,"NA",unit,cur)$(not par_combalem(tmp_reg,milestonyr,tmp_comNRGin,"annual"))
         = par_combalem(tmp_reg,milestonyr,tmp_comNRGin,all_ts)$(
            com_unit(tmp_reg,tmp_comNRGin,unit)
            and g_rcur(tmp_reg,cur));;

*= Annual price of commodity input (commmodity on annual level)
         TIMESReport(scen,sector,"prices","apri" ,"NA",tmp_comNRGin,"annual",tmp_reg,tmp_reg,milestonyr,"NA",unit,cur) =
                    par_CombalEm(tmp_reg,milestonyr,tmp_comNRGin,"annual")$(
             com_unit(tmp_reg,tmp_comNRGin,unit)
             and g_rcur(tmp_reg,cur));

*= Annual price of commodity (commmodity on ts level - calculated weighted by using G_YRFR)
        TIMESReport(scen,sector,"prices","apri" ,"NA",tmp_comNRGin,"annual",tmp_reg,tmp_reg,milestonyr,"NA",unit,cur)$(not par_CombalEm(tmp_reg,milestonyr,tmp_comNRGin,"annual"))
        = sum(all_TS,  par_CombalEm(tmp_reg,milestonyr,tmp_comNRGin,all_TS) * G_YRFR(tmp_reg, all_TS))$(
            com_unit(tmp_reg,tmp_comNRGin,unit)
            and g_rcur(tmp_reg,cur));

*elapsedTIME("report","prices") = TIMEelapsed;

*       Revenue from process fuel output
        TIMESReport(scen,sector,"acosts","flor" ,tmp_prc,tmp_comNRGout,"ANNUAL",tmp_reg,tmp_reg,milestonyr,vntg,"NA",cur)$(prc_desc(tmp_reg,tmp_prc)
                                                                                                                           and val_flo(tmp_reg,vntg,milestonyr,tmp_prc,tmp_comNRGout) lt 0)
        =  (val_flo(tmp_reg,vntg,milestonyr,tmp_prc,tmp_comNRGout))$(
           g_rcur(tmp_reg,cur));

*       Fuel cost
        TIMESReport(scen,sector,"acosts","floc" ,tmp_prc,tmp_comNRGin,"ANNUAL",tmp_reg,tmp_reg,milestonyr,vntg,"NA",cur)$(prc_desc(tmp_reg,tmp_prc)
                                                                                                                          and val_flo(tmp_reg,vntg,milestonyr,tmp_prc,tmp_comNRGin) gt 0)
        =  (val_flo(tmp_reg,vntg,milestonyr,tmp_prc,tmp_comNRGin))$(
            g_rcur(tmp_reg,cur));

*       Flow energy taxes 
        TIMESReport(scen,sector,"acosts","flox" ,tmp_prc,tmp_comNRGin,'ANNUAL',tmp_reg,tmp_reg,milestonyr,vntg,"NA",cur)$(prc_desc(tmp_reg,tmp_prc)
                                                                                                                          and cst_flox(tmp_reg,vntg,milestonyr,tmp_prc,tmp_comNRGin) ge 0)
       = cst_flox(tmp_reg,vntg,milestonyr,tmp_prc,tmp_comNRGin)$(
         g_rcur(tmp_reg,cur));

*       Flow emission taxes
        TIMESReport(scen,sector,"acosts","flox" ,tmp_prc,tmp_comEMISout,'ANNUAL',tmp_reg,tmp_reg,milestonyr,vntg,"NA",cur)$(prc_desc(tmp_reg,tmp_prc)
                                                                                                                            and cst_flox(tmp_reg,vntg,milestonyr,tmp_prc,tmp_comEMISout) ge 0
                                                                                                                            and not comETS(tmp_comEMISout))
       = cst_flox(tmp_reg,vntg,milestonyr,tmp_prc,tmp_comEMISout)$(
           g_rcur(tmp_reg,cur));

*       Flow emission trading system (ETS)
        TIMESReport(scen,sector,"acosts","floq" ,tmp_prc,tmp_comEMISout,'ANNUAL',tmp_reg,tmp_reg,milestonyr,vntg,"NA",cur)$(prc_desc(tmp_reg,tmp_prc)
                                                                                                                            and cst_flox(tmp_reg,vntg,milestonyr,tmp_prc,tmp_comEMISout) ge 0
                                                                                                                            and comETS(tmp_comEMISout))
       = cst_flox(tmp_reg,vntg,milestonyr,tmp_prc,tmp_comEMISout)$(
           g_rcur(tmp_reg,cur));

*       Flow energy subsidies
        TIMESReport(scen,sector,"acosts","flos" ,tmp_prc,tmp_comNRGin,"annual",tmp_reg,tmp_reg,milestonyr,vntg,"NA",cur)$(prc_desc(tmp_reg,tmp_prc)
                                                                                                                          and cst_flox(tmp_reg,vntg,milestonyr,tmp_prc,tmp_comNRGin) le 0)
        = cst_flox(tmp_reg,vntg,milestonyr,tmp_prc,tmp_comNRGin)$(
          g_rcur(tmp_reg,cur));

*       GHG mitigation subsidy
        TIMESReport(scen,sector,"acosts","flos" ,tmp_prc,tmp_comEMISout,"annual",tmp_reg,tmp_reg,milestonyr,vntg,"NA",cur)$(prc_desc(tmp_reg,tmp_prc)
                                                                                                                            and cst_flox(tmp_reg,vntg,milestonyr,tmp_prc,tmp_comEMISout) le 0)
        = cst_flox(tmp_reg,vntg,milestonyr,tmp_prc,tmp_comEMISout)$(
          g_rcur(tmp_reg,cur));

*       Variable O&M cost
        TIMESReport(scen,sector,"acosts","actc" ,tmp_prc,"NA","annual",tmp_reg,tmp_reg,milestonyr,vntg,"NA",cur)$(prc_desc(tmp_reg,tmp_prc))                                                                         
        = cst_actc(tmp_reg,vntg,milestonyr,tmp_prc,"-")$(
          g_rcur(tmp_reg,cur));

*       Fixed O&M cost
        TIMESReport(scen,sector,"acosts","fixc" ,tmp_prc,"NA","annual",tmp_reg,tmp_reg,milestonyr,vntg,"NA",cur)$(prc_desc(tmp_reg,tmp_prc))
        = cst_fixc(tmp_reg,vntg,milestonyr,tmp_prc)$(
        g_rcur(tmp_reg,cur));

*       Fixed O&M taxes
        TIMESReport(scen,sector,"acosts","fixx" ,tmp_prc,"NA","annual",tmp_reg,tmp_reg,milestonyr,vntg,"NA",cur)$(prc_desc(tmp_reg,tmp_prc)
                                                                                                                  and cst_fixx(tmp_reg,vntg,milestonyr,tmp_prc) ge 0)
        = cst_fixx(tmp_reg,vntg,milestonyr,tmp_prc)$(
          g_rcur(tmp_reg,cur));

*       Fixed O&M subsidies
        TIMESReport(scen,sector,"acosts","fixs" ,tmp_prc,"NA","annual",tmp_reg,tmp_reg,milestonyr,vntg,"NA",cur)$(prc_desc(tmp_reg,tmp_prc)
                                                                                                                  and cst_fixx(tmp_reg,vntg,milestonyr,tmp_prc) lt 0)
        = cst_fixx(tmp_reg,vntg,milestonyr,tmp_prc)$(
          g_rcur(tmp_reg,cur));

*       Annual invesment cost 
        TIMESReport(scen,sector,"acosts","invc" ,tmp_prc,"NA","annual",tmp_reg,tmp_reg,milestonyr,vntg,"NA",cur)$(prc_desc(tmp_reg,tmp_prc))
        = cst_invc(tmp_reg,vntg,milestonyr,tmp_prc,"INV")$(
          g_rcur(tmp_reg,cur));

*       Annual investment taxes
        TIMESReport(scen,sector,"acosts","invx" ,tmp_prc,"NA","annual",tmp_reg,tmp_reg,milestonyr,vntg,"NA",cur)$(prc_desc(tmp_reg,tmp_prc)
                                                                                                                  and cst_invx(tmp_reg,vntg,milestonyr,tmp_prc,"INV") ge 0)
        = cst_invx(tmp_reg,vntg,milestonyr,tmp_prc,"INV")$(
          g_rcur(tmp_reg,cur));

*       Annual investment subsidy
        TIMESReport(scen,sector,"acosts","invx" ,tmp_prc,"NA","annual",tmp_reg,tmp_reg,milestonyr,vntg,"NA",cur)$(prc_desc(tmp_reg,tmp_prc)
                                                                                                                  and cst_invx(tmp_reg,vntg,milestonyr,tmp_prc,"INV") lt 0)
        = cst_invx(tmp_reg,vntg,milestonyr,tmp_prc,"INV")$(
         g_rcur(tmp_reg,cur));

*       Decomission costs 
        TIMESReport(scen,sector,"acosts","decc" ,tmp_prc,"NA","annual",tmp_reg,tmp_reg,milestonyr,vntg,"NA",cur)$(prc_desc(tmp_reg,tmp_prc)
                                                                                                                  and cst_invx(tmp_reg,vntg,milestonyr,tmp_prc,"INV") lt 0)
        = cst_decc(tmp_reg,vntg,milestonyr,tmp_prc)$(
         g_rcur(tmp_reg,cur));

*elapsedTIME("report","acosts") = TIMEelapsed;

*       Average annual lumpsum investment (excluding hurdle rate)
        TIMESReport(scen,sector,"lumpsum","inv_" ,tmp_prc,"NA","annual",tmp_reg,tmp_reg,milestonyr,vntg, "NA",cur)$(prc_desc(tmp_reg,tmp_prc))
         = (cap_new(tmp_reg,vntg,tmp_prc,milestonyr,"lumpinv") / periodlength(milestonyr))$(
           g_rcur(tmp_reg,cur));

*       Average annual lumpsum investment (including hurdle rate)
        TIMESReport(scen,sector,"lumpsum","invc" ,tmp_prc,"NA","annual",tmp_reg,tmp_reg,milestonyr,vntg, "NA",cur)$(prc_desc(tmp_reg,tmp_prc))
        = ((cap_new(tmp_reg,vntg,tmp_prc,milestonyr,"lumpinv") + cap_new(tmp_reg,vntg,tmp_prc,milestonyr,"inv+")) / periodlength(milestonyr))$(
           g_rcur(tmp_reg,cur));

*       Average annual lumpsum investment subsidy (including effect of hurdle rate)
        TIMESReport(scen,sector,"lumpsum","invx" ,tmp_prc,"NA","annual",tmp_reg,tmp_reg,milestonyr,vntg,"NA",cur)$(prc_desc(tmp_reg,tmp_prc)
                                                                                                                  and cap_new(tmp_reg,vntg,tmp_prc,milestonyr,"lumpix") ge 0)
        = ((cap_new(tmp_reg,vntg,tmp_prc,milestonyr,"lumpix") + cap_new(tmp_reg,vntg,tmp_prc,milestonyr,"invx+")) / periodlength(milestonyr))$(
          g_rcur(tmp_reg,cur));

*       Average annual lumpsum investment subsidy (including effect of hurdle rate)
        TIMESReport(scen,sector,"lumpsum","invs" ,tmp_prc,"NA","annual",tmp_reg,tmp_reg,milestonyr,vntg,"NA",cur)$(prc_desc(tmp_reg,tmp_prc)
                                                                                                                   and cap_new(tmp_reg,vntg,tmp_prc,milestonyr,"lumpix") lt 0)
        = ((cap_new(tmp_reg,vntg,tmp_prc,milestonyr,"lumpix") + cap_new(tmp_reg,vntg,tmp_prc,milestonyr,"invx+")) / periodlength(milestonyr))$(
          g_rcur(tmp_reg,cur));

**= Capacity section (unit varies and information is not directly availble in gdx - output from TIMES)
*       Activity level of proces (particular relevant for storage technologies)
        TIMESReport(scen,sector,"capacity","actl" ,tmp_prc,tmp_comNRGout,all_TS,tmp_reg,tmp_reg,milestonyr,vntg,unit,"NA")$(prc_desc(tmp_reg,tmp_prc)
                                                                                                                        and tmp_prcsts(tmp_prc))
        = var_act_level(tmp_reg,vntg,milestonyr,tmp_prc,all_ts)$(
            prc_actunt(tmp_reg,tmp_prc,tmp_comNRGout,unit));
	    
*       Residual capacity 
        TIMESReport(scen,sector,"capacity","ecap" ,tmp_prc,"NA","annual",tmp_reg,tmp_reg,milestonyr,"NA",units_cap,"NA")$(prc_desc(tmp_reg,tmp_prc))
         =  (par_pasti(tmp_reg,milestonyr,tmp_prc,"0"))$(
             map_prc_capacityunit(tmp_prc,units_cap));

*       Retired capacity    
        TIMESReport(scen,sector,"capacity","rcap" ,tmp_prc,"NA","annual",tmp_reg,tmp_reg,milestonyr,"NA",units_cap,"NA")$(prc_desc(tmp_reg,tmp_prc))
         =  (par_pasti(tmp_reg,milestonyr,tmp_prc,"¤"))$ (
             map_prc_capacityunit(tmp_prc,units_cap));
    
*       New capacity
        TIMESReport(scen,sector,"capacity","ncap" ,tmp_prc,"NA","annual",tmp_reg,tmp_reg,milestonyr,"NA",units_cap,"NA")$(prc_desc(tmp_reg,tmp_prc))
        = par_capl(tmp_reg,milestonyr,tmp_prc)$(
          map_prc_capacityunit(tmp_prc,units_cap));

*       Total capacity
        TIMESReport(scen,sector,"capacity","tcap" ,tmp_prc,"NA","annual",tmp_reg,tmp_reg,milestonyr,"NA",units_cap,"NA")$(prc_desc(tmp_reg,tmp_prc))
         =  (par_capl(tmp_reg,milestonyr,tmp_prc) + par_pasti(tmp_reg,milestonyr,tmp_prc,"0") + par_pasti(tmp_reg,milestonyr,tmp_prc,"¤"))$(
             map_prc_capacityunit(tmp_prc,units_cap));

*       Levelised cost of proces
        TIMESReport(scen,sector,"capacity","levc" ,tmp_prc,com,"annual",tmp_reg,tmp_reg,milestonyr,"NA",unit,cur)$(prc_desc(tmp_reg,tmp_prc))
        = par_ncapr(tmp_reg, milestonyr, tmp_prc, "LEVCOST")$(
            prc_actunt(tmp_reg,tmp_prc,com,unit)
            and g_rcur(tmp_reg,cur));

*elapsedTIME("report","capacity") = TIMEelapsed;

elapsedTIME("report_loop",sector) = TIMEelapsed;
countprc("count",sector)     = card(tmp_prc);

);


*============================================================================================
* 7 Test section: Sum check to confirm that TIMES report includes all data (f_in and f_out)
*===========================================================================================
* This section performs sum-check on F_IN and F_out form the raw TIMES gdx output file and the TIMESreport parameter

PARAMETERS SumTEST(*,attr,milestonyr,com,prc)  "Sum check to ensure correspondance between TIMES gdx file and TIMESReport"
           SumCheck_(attr,milestonyr,com,prc)  "Check difference between TIMES gdx and TIMESreport "
           tolerance                           "Define tolerance for sum chekcs"                           /1e-06/ ;

*Sum over data in TIMESgdx
SumTEST("TIMESgdx","F_in",milestonyr,com,prc)    = sum((all_reg,vntg,all_TS),F_in(all_reg,vntg,milestonyr,prc,com,all_TS));
SumTEST("TIMESreport","F_in",milestonyr,com,prc) = sum((scen,sector,topic,all_TS,all_reg,all_regT,vntg,unit,cur), TIMESReport(scen,sector,topic,"f_in",prc,com,all_TS,all_reg,all_regT,milestonyr,vntg,unit,cur));

SumTEST("TIMESgdx","F_Out",milestonyr,com,prc)    = sum((all_reg,vntg,all_TS),F_out(all_reg,vntg,milestonyr,prc,com,all_TS));
SumTEST("TIMESreport","F_Out",milestonyr,com,prc) = sum((scen,sector,topic,all_TS,all_reg,all_regT,vntg,unit,cur), TIMESReport(scen,sector,topic,"f_out",prc,com,all_TS,all_reg,all_regT,milestonyr,vntg,unit,cur));

SumCheck_(attr,milestonyr,com,prc)$(ABS(SumTEST("TIMESreport",attr,milestonyr,com,prc) - SumTEST("TIMESgdx",attr,milestonyr,com,prc)) > tolerance ) = SumTEST("TIMESreport",attr,milestonyr,com,prc) - SumTEST("TIMESgdx",attr,milestonyr,com,prc);
display SumCheck_;

execute$(sum((attr,milestonyr,com,prc),ABS(SumCheck_(attr,milestonyr,com,prc))) > tolerance) 'msg "%username%" /time:0 Aborted due to difference between data in TIMES gdx and TIMES report script: & /UIzCheck/' ;
ABORT$(sum((attr,milestonyr,com,prc),ABS(SumCheck_(attr,milestonyr,com,prc))) > tolerance) "ERROR: Aborted due to difference between data in TIMES gdx and TIMES report script";

elapsedTIME("post","07TestResults") = TIMEelapsed;

*============================================================================================
* 8 expanding timesreport with additional dimensions
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
