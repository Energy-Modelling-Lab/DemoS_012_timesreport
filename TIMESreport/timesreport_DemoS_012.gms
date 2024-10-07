*===========================================================================================
*  Copyright (C) 2024 Kristoffer S. Andersen (kristoffer@energymodellinglab.com)
*                Energy modelling lab (https://energymodellinglab.com/).
*
*  This software is  open source: you can redistribute it and/or modify it
*  under the terms of the GNU General Public License v3.0 (see file NOTICE-GPLv3.txt).
*  For further information, visit: <https://www.gnu.org/licenses/gpl-3.0.html>.
*
*  This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
*  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*===========================================================================================

$title   TIMES demo12 report - Collects all relevant data from TIMES demo into one parameter

$ontext
*Overview of code (07/10/2024)
*=== 0 Define setglobal if not set externally 
*=== 1 Define sets and parameter for TIMES reporting
*=== 2 Declare TIMES default sets, parameters, variables and equations
*=== 3 Define sets an parameters to import times solution
*=== 4 Basic check and export of dummies in model
*=== 5 General period and proces maps definitions
*=== 6 Reporting TIMES default model results
*=== 7 Test section (abort if test fails)
*=== 8 Expanded TIMES reporting 
*=== 9 Write restults to gdx and csv
$offtext

*============================================================================================
* 0 Define setglobal if not set externally 
*============================================================================================
*Time lapse parameter
PARAMETER  elapsedTIME(*,*) "Time elapsed until Parameter used to check progress of code"
           countprc(*,*)    "Count number of processes by sector";

* Set name of TIMES name (this set is set directly from VEDA using $case_name)
$IF NOT '%TIMESscenario%' $SETGLOBAL TIMESscenario DemoS_012

* If-statements are created to ensure that data is extracted from the correct GDX-file.
$IF not exist '%pathTIMES%'   $SETGLOBAL pathTIMES  "c:\VEDA\GAMS_WrkTIMES"

* If-statements are created to ensure that data is extracted from the correct GDX-file.
$IF not exist '%pathTIMESmodel%'   $SETGLOBAL pathTIMESmodel  "..\"

*============================================================================================
* 1 Define sets and parameter for TIMES default reporting (complication time)
*============================================================================================

SET     sector          "Sector labels" /
        ENERGYSYSTEM    "Energy system"
        ELECTRICITY     "Electricity supply"
        INDUSTRY        "Industry"
        MINING          "Mining"
        TRADE           "Trade"
        REFINERY        "Refinery"
        AGRICULTURE     "Agriculture"
        COMMERCIAL      "Commercial"
        RESIDENTIAL     "Residential"
        TRANSPORT       "Transport"
        TRANSMISSION    "Transmission of gas and electricity"
        "_na"           "Not assigned"
/;

SET     topic           "Reporting topics from TIMES" /
        material         "Material input or output, kton"
        emission        "GHG and other emissions"
        savings         "Energy savings"
        energy          "Final energy demand"
        service         "Energy service demand"
        dcosts          "Discounted cost"
        lumpsum         "Lumpsum investment and subsidies (average annual)"
        capacity        "Capacity"
        prices          "Prices"
        revenue         "Revenue, e.g. from electricity trade"
        constraint      "Information on constraints"
        inputpar        "Model input parameters"
/;

SET     attr            "TIMES default attributes for reporting" /
        actc            "Activitiy cost, mio kr"
        invc            "Investment cost including hurdle rate, mio kr"
        inv_            "Investment cost excluding hurdle rate, mio kr"
        invx            "Annual discounted investment taxes, mio kr"
        invs            "Annual discounted investment subsidies, mio kr"
        salv            "Salvage cost, mio kr"
        fixc            "Fixed O&M cost, mio kr"
        fixx            "Fixed O&M taxes, mio kr"
        fixs            "Fixed O&M subsidies, mio kr"
        floc            "Fuel cost, mio kr"
        flox            "Fuel taxes, mio kr"
        flos            "Fuel subsidies, mio kr"
        floq            "Emission trading system, mio kr"
        instcap         "new cacapcity installed in period, MW or PJ"
        fout            "commodity output from process, PJ or kton"
        f_in            "commodity input to process, PJ or kton"
        levc            "levelized cost of energy including emission, kr/GJ"
        mpri            "Market/shadow price of commodity balance, kr/GJ"
        apri            "Average price, kr/GJ"
        proj            "Energy service demand"
        ncap            "new capacity within period"
        cap_            "total capacity within period"
        mcon            "Market/shadow price of user constraint"
        afa             "Availability factor annual"
        actl            "Activity level particular relevant for storage technologies"
        objsal          "Objective function salvage cost"
        objfix          "Objective function fixed cost"
        objinv          "Objective function investment cost"
        objvar          "Objective function variable cost"
        objdam          "Objective function damage cost"
        yrfr            "Time slice fractions"
/;

*SET     unit            "Units used for reporting" /
*        "_na"/;

elapsedTIME("ante","01setTIMESreport") = TIMEelapsed;

*============================================================================================
* 2 Declare TIMES default sets, parameters, variables and equations (complication time)
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


*Define alias as needed
ALIAS(INV, INVT);
ALIAS(prc,prcT);
ALIAS(com,comT,comTT,comI,comO);
ALIAS(reg,regT);
ALIAS(all_reg,all_regT,regTo,regFrom);
ALIAS(all_ts,ts);
ALIAS(cur,curr);

*============================================================================================
* 2.1 Import set definition from TIMES default model run (note this is a precondition for importing results)
*============================================================================================
* Load basic sets from TIMES at compilation time
$gdxin "%pathTIMES%\%TIMESscenario%\GamsSave\%TIMESscenario%.gdx"
$load  prc prc_desc prc_grp com com_desc com_grp all_reg reg all_TS com_TS prc_Map top milestonyr periodyr eohyears allyear top_ire ie=impexp prc_gmap com_gmap units units_com units_act units_cap units_mony com_unit cur g_rcur
$gdxin
;

$onMulti
*set unit /set.units/ ;
set cur     /"_na"/;
set units   /"_na" , "capacity_unit"/;
set all_reg /"_na"/;
$offMulti


elapsedTIME("ante","02setTIMESsolution") = TIMEelapsed;

*============================================================================================
* 3 Define sets an parameters to import times solution
*============================================================================================
SETS
        year(milestonyr)        "year relevant for linking iterating with cge"
        loopyears(milestonyr)   "year relevant for linking iterating with cge"
        vntg                    "Vintage"                               /1980*2100/
        newcap                  "New capacitiy dimensions"              /INSTCAP, LUMPINV, LUMPIX, INVX+, INV+/
        bd                      "Bound in GAMS"                         /UP, LO, FX, L/
        auxiliary               "Auxiliary set, used if dim is empty"   /'-'/
        item                    "Var_cap information"
                                /       '0'     "Residual capacity"
                                        '¤'     "Retired capacity"
                                        '-'     "New capacity"/;


*add option to leave dimension blank when no proces or commoditity information is not available
$onMulti
set prc /"_na"/;
set com /"_na"/;
set vntg /"_na"/;
$offMulti

* Define years based on milestone model years in TIMES default
        year(milestonyr)      = YES;

* Loopyears (relevant when linking with external model)
        loopyears(milestonyr) = YES;


SCALAR  timesErrorLevel         "TIMES error level from GAMS execution"           / 0 /
        g_dyear                 "Discount year";

PARAMETER
*Collect year values from times (filtering for milesonyr only - this might be a problem if you discount to a year outside the milestonyr definition)
        YEARVAL(milestonyr)                                "TIMES year values"
*Total discounted system cost (NOTICE: that it is the parameter OBJZ.l that is used from the gdx-file)TIMES objective value";
        VAR_OBJ_L(regT,var_obj_items,cur)               "TIMES objective value"
*Projected annual demand given in region (r), specified year (datayear) for commodity (c)
        com_proj(regT,milestonyr,com)                   "TIMES energy service demand"
*Commodity consumption by Process given in region (r), vintage of process (v), modelled period (t), specific process (p), input flow of commodity (c) at certain timeslice (s)
        F_in(all_regT,vntg,milestonyr,prcT,comT,all_TS)     "TIMES energy inputs"
*Commodity Production by Process  given in region (r), vintage of process (v), modelled period (t), specific process (p), output flow of commodity (c) at certain timeslice (s)
        F_out(all_regT,vntg,milestonyr,prcT,comT,all_TS)    "TIMES energy outputs"
* Annual flow cost (undiscounted) given in region (r), vintage of process (v), modelled period (t), specific process (p) and associated commodity (c) (NOTICE: that a process can have multiple associated commodities and therefore multiple indicies for cst_floc)
        cst_floc(regT,vntg,milestonyr,prcT,comT)        "TIMES fuel costs"
*Annual flow taxes/subsidies (undiscounted) given in region (r), vintage of process (v), modelled period (t), specific process (p) and associated commodity (c) (NOTICE: taxes are seen as positive (+ increasing objective (OBJ) function) and subsidies as negative (- decreasing OBJ function))
        cst_flox(regT,vntg,milestonyr,prcT,comT)        "TIMES fuel taxes and subsidies"
*Annual aciticty cost (undiscounted) given in region (r), vintage of process (v), modelled period (t), specific process (p) and Additional indicator for start-up costs (uc_n)
        cst_actc(regT,vntg,milestonyr,prcT,*)           "TIMES aciticty cost"
        cst_salv(regT,milestonyr,prcT)                  "TIMES salvage costs"
*Annual fixed operating and maintenance costs (undiscounted) given in region (r), vintage of process (v), modelled period (t) and specific process (p)
        cst_fixc(regT,vntg,milestonyr,prcT)             "TIMES fixed O&M costs"
*Annual fixed taxes/subsidies (undiscounted) given in region (r), vintage of process (v), modelled period (t) and specific process (p)
        cst_fixx(regT,vntg,milestonyr,prcT)             "TIMES fixed O&N taxes"
*Annual investment costs (undiscounted)  given in region (r), vintage of process (v), modelled period (t), specific process (p) and additional indicator for ***** (uc_n)
        cst_invc(regT,vntg,milestonyr,prcT,invT)        "TIMES investment costs"
*Annual investment taxes/subsidies (undiscounted)  given in region (r), vintage of process (v), modelled period (t), specific process (p) and additional indicator for ***** (uc_n)
        cst_invx(regT,vntg,milestonyr,prcT,invT)        "TIMES investment taxes/subsidies"
*new capacity parameters related to installed capacity or lumpsum investment given in region (r), vintage of process (v), modelled period (t), specific process (p) and additional indicator to seperate the specific informations e.g. newly installed capacity, lumpsum investments etc.
        cap_new(regT,vntg,prcT,milestonyr,newcap)       "TIMES lump sum investment, costs and subsidies"
*Alot of information regarding technology investment, but is mainly used for its levelized cost. Is given by region (r), modelled period (t), specific process (p) and additional indicators, where the LEVCOST is of specific interest here, and the only one taken out.
        par_ncapr(regT, milestonyr, prcT, ncapr_items)  "TIMES levelised cost of energy"
        par_ncapr_(regT, milestonyr, prcT)              "TIMES levelised cost of energy, only levcost"
*Shadow price (undiscounted) of commodity balance - being a strict equality (AKA. Commodity Slack/Levels - Marginals) given in region (r), modelled period (t), of commodity (c) (e.g. increase of production or decrease of consumption)
        par_CombalEm(regT,milestonyr,com,all_TS)        "TIMES shadow price on commodity balance"
        var_comprd(regT,milestonyr,com,all_TS)          "TIMES commodity production"
        var_flo(regT,vntg,milestonyr,prc,com,all_TS)    "TIMES commodity flows"
*Reporting var_act_level to get TS activity level
        var_act_level(regT,vntg,milestonyr,prcT,all_TS)       "Overall activity of process (level)"
*New technology capacity given in region (r), modelled period (t) and for specific process (p) (Notice: that the specific perimiter extracted is the var_ncap.l, which is the level or the actual realized new capacity in the model)
        var_ncap(all_regT,milestonyr,prcT)                  "TIMES new capacity"
*Capacity of a technology given in region (r), modelled period (t) and for specific process (p)  (Notice: that the specific perimiter extracted is the var_cap.l, which is the level or the actual realized capacity in the model)
        var_cap(all_RegT,milestonyr,prcT)                   "TIMES total capacity"
*Residual capacity of past investments given in region (r), for modelled period (t), for specific process (p) with vintage (v)
        par_pasti(all_regT,milestonyr,prcT,item)            "TIMES pasti-capacitiy available in each period"
*Technology capacity given in region (r), in modelled period (t) for specific process (p)
        par_capl(all_regT,milestonyr,prcT)                  "TIMES non-pasti capacity available in each period"
*Information on import and export prices in selected currency
        ire_price(all_regT,milestonyr,prcT,com,all_TS,reg,ie,cur) "Exogenous price of import/export"
*Value flow by processes (i.e. f_in x combalem)
        val_flo(regT,vntg, milestonyr, prcT, com)       "Value flow by processes"
*Relationship between capacity and acticity in the model
        coef_af(regT,vntg,milestonyr, prcT,all_TS,bd)    "Capacity/Activity relationship (model input)"
*Primary commodity and activity unit
        prc_actunt(all_regT,prcT,com,units)                  "Primary commodity and activity unit"
* Time-slice fraction information
        G_YRFR(regT, all_TS)                             "Time-slice fraction information"
;

*Explanation of the different inputs from the above chosen gdx-file. This information can also be found on in the documentation "https://iea-etsap.org/docs/Documentation_for_the_TIMES_Model-Part-II.pdf"
*Notice: that all input sets of the below stated parameters should be filled out in a relatable set, which can either be translated in a script later or in the current file

*============================================================================================
* 3.1 Load results from TIMES default and do initial corrections to reduces size of data (execution time)
*============================================================================================
execute_load  "%pathTIMES%\%TIMESscenario%\GamsSave\%TIMESscenario%.gdx"         cst_actc, cst_floc, cst_flox, cst_fixc, cst_fixx, cst_invc, cst_invx, F_in, F_out, par_COMBALem,cap_new, com_proj, par_ncapr, val_flo, var_ncap=var_ncap.l, var_cap = var_cap.l, par_pasti, par_capl, ire_price, coef_af, VAR_OBJ_L=VAR_OBJ.l, G_YRFR,         prc_actunt, var_act_level = var_act.l, g_dyear,yearval;


* Reset "EPS's" to zero to reduce data size and makes sure that output is always numerical
cst_actc(regT,vntg,milestonyr,prcT,auxiliary)$(cst_actc(regT,vntg,milestonyr,prcT,auxiliary) eq EPS)                    = 0;
cst_floc(regT,vntg,milestonyr,prcT,comT)$(cst_floc(regT,vntg,milestonyr,prcT,comT) eq EPS)                              = 0;
cst_flox(regT,vntg,milestonyr,prcT,comT)$(cst_flox(regT,vntg,milestonyr,prcT,comT) eq EPS)                              = 0;
cst_fixc(regT,vntg,milestonyr,prcT)$(cst_fixc(regT,vntg,milestonyr,prcT) eq EPS)                                        = 0;
cst_fixx(regT,vntg,milestonyr,prcT)$(cst_fixx(regT,vntg,milestonyr,prcT) eq EPS)                                        = 0;
cst_invc(regT,vntg,milestonyr,prcT,invT)$(cst_invc(regT,vntg,milestonyr,prcT,invT) eq EPS)                              = 0;
cst_invx(regT,vntg,milestonyr,prcT,invT)$(cst_invx(regT,vntg,milestonyr,prcT,invT) eq EPS)                              = 0;
F_in(regT,vntg,milestonyr,prcT,comT,all_TS)$(F_in(regT,vntg,milestonyr,prcT,comT,all_TS) eq EPS)                        = 0;
F_out(regT,vntg,milestonyr,prcT,comT,all_TS)$(F_out(regT,vntg,milestonyr,prcT,comT,all_TS) eq EPS)                      = 0;
par_CombalEm(regT,milestonyr,com,all_TS)$(par_CombalEm(regT,milestonyr,com,all_TS) eq EPS)                              = 0;
cap_new(regT,vntg,prcT,milestonyr,newcap)$(cap_new(regT,vntg,prcT,milestonyr,newcap) eq EPS)                            = 0;
com_proj(regT,milestonyr,com)$(com_proj(regT,milestonyr,com) eq EPS)                                                    = 0;
par_ncapr(regT, milestonyr, prcT, ncapr_items)$(par_ncapr(regT, milestonyr, prcT, ncapr_items) eq EPS)                  = 0;
var_ncap(regT,milestonyr,prcT)$(var_ncap(regT,milestonyr,prcT)  eq EPS)                                                 = 0;
var_cap(RegT,milestonyr,prcT)$(var_cap(RegT,milestonyr,prcT)    eq EPS)                                                 = 0;
var_act_level(regT,vntg,milestonyr,prcT,all_TS)$(var_act_level(regT,vntg,milestonyr,prcT,all_TS) eq EPS)                = 0;
par_pasti(regT,milestonyr,prcT,"0")$(par_pasti(regT,milestonyr,prcT,"0") eq EPS)                                        = 0;
par_pasti(regT,milestonyr,prcT,"¤")                                                                                     = 0;
par_capl(regT,milestonyr,prcT)$(par_capl(regT,milestonyr,prcT) eq EPS)                                                  = 0;
ire_price(regT,milestonyr,prcT,com,all_TS,reg,ie,cur)$(ire_price(regT,milestonyr,prcT,com,all_TS,reg,ie,cur) eq EPS)    = 0;
val_flo(regT,vntg,milestonyr,prcT,com)$(val_flo(regT,vntg,milestonyr,prcT,com) eq EPS)                                  = 0;
coef_af(regT,vntg,milestonyr, prcT,all_TS,bd)$(coef_af(regT,vntg,milestonyr, prcT,all_TS,bd) eq EPS)                    = 0;

elapsedTIME("ante","03importTIMESresults") = TIMEelapsed;

*============================================================================================;
* 4 Basic check for dummies in model
*============================================================================================

Parameter       timesDummies(regT,vntg,milestonyr,prcT,comT,all_TS)            "TIMES dummies - if any"
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
timesDummies(regT,vntg,year,prcDM,comT,all_TS) = F_out(regT,vntg,year,prcDM,comT,all_TS);
* Defining timesDummiesFlag, which is a parameter that flags out which years are affected by dummies - And also where they are affected the most.
timesDummiesFlag(year) = sum((regT,vntg,prcDM,comT,all_TS), timesDummies(regT,vntg,year,prcDM,comT,all_TS));

* Creating if-statement that creates a massage for the user - to see that dummies are present, these are also displayed in the lst-file running the current gms-file.
        IF(sum(year, timesDummiesFlag(year)) gt  0,
                DISPLAY  timesDummiesFlag,timesdummies;
                execute 'msg "%username%" /time:0 Dummies present in TIMES demo solution. For detailed information see:  %pathTIMESmodel%Results\TimesDummies_%TIMESscenario%.gdx';
* Write information related to dummies to a gdx-file in the temp-library
                execute_unload '%pathTIMESmodel%TIMESreport\GDX\%TIMESscenario%_TimesDummies.gdx',
                timesDummies;
        );


        IF(timesErrorLevel ne 0,
                DISPLAY  timesErrorLevel;
                execute 'msg "%username%" /time:0 TIMES ERROR SEE TIMES SOLVER STATUS';
        );

elapsedTIME("ante","04dummiesTIMES") = TIMEelapsed;

*============================================================================================
* 5 General period and proces maps definitions
*============================================================================================

*============================================================================================
* 5.1 Determine period length of milestone years based on TIMES default solution
*============================================================================================
* Note this section could be replaced by simply importing the Parameter D from the gdx file) 

SET pyear               "Define set year used to calculate length of milesone year";
SET periodlength_       "Define set to help calculate length of milesone year";

*Define parameter
parameter periodlength  "Define parameter used to determine the number of years in a TIMES default period/milestone year definition";

*Define years as relevant years used in the TIMES default model
pyear(eohyears) = YES;

*Define mapping years and TIMES default milestone definition
periodlength_(milestonyr,pyear) = periodyr(milestonyr,pyear);

*Define period calculating the number of years in each TIMES default milestone definition (used to calculate average annual lumpsum investment)
periodlength(milestonyr)        = sum(pyear, 1$periodyr(milestonyr,pyear));

*============================================================================================
* 5.2 Create maps of processes and commodities based on TIMES-solution
*============================================================================================
set     topPC(prc,com,in_out)   "Map processes to their commodity input and output for the present TIMES default solution"
        comSrv(com)             "Map energy service demands in the TIMES default solution gdx-file"
        comNRG(com)             "Map fuel input in the TIMES default solution gdx-file"
        comENV(com)             "Map environmental emissions commodities"
        comETS(com)
        comMAT(com)             "Map material variables like cement";

* map processed based on their commodity input and output
topPC(prc,com,in_out) = SUM(reg, top(reg,prc,com,in_out));

*comSrv(com)       = YES$SUM((i,tescom)$tescom(com),1$secSrv(i,tescom));
comSrv(com)       = YES$sum(reg, com_gmap(reg,"DEM",com));
comNRG(com)       = YES$sum(reg, com_gmap(reg,"NRG",com));
comENV(com)       = YES$sum(reg, com_gmap(reg,"ENV",com));
comMAT(com)       = YES$sum(reg, com_gmap(reg,"MAT",com));

*============================================================================================
* 5.3 Define termporay set used for reporting purposes
*============================================================================================

SET     tmp_prc(prc)            "temporary proces list"
        tmp_prctrd(prc)         "temporary trade proces list"
        tmp_prcsav(prc)         "temporary savings proces list"
        tmp_comNRGin(com)       "temporary list of energy inputs"
        tmp_comNRGout(com)      "temporary list of energy output"
        tmp_comEMISin(com)      "temporary list of emission input commodities"
        tmp_comEMISout(com)     "temporary list of emission output commodities"
        tmp_comMATin(com)       "temporary list of material input commodities"
        tmp_comMATout(com)      "temporary list of material output commodities"
        tmp_comSrvout(com)      "temporary list of energy services";

elapsedTIME("ante","05TIMESreportmaps") = TIMEelapsed;

*============================================================================================
* 5.4 Extend prc_gmap to also cover prc that have not been assigned a sectors in VEDA
*============================================================================================
* Processes (prc) that are not included in the prc_gmap from TIMES gets the label "_NA" (not 
* assigned)  This is done to make that sure that data had has not been assgined a sector in VEDA
* is also included in the TIMESreport

prc_gmap(reg,prc,"_NA")$(not sum((sector,regT), prc_gmap(regT,prc,sector))) = YES;

*============================================================================================
* 6 Reporting TIMES default model results
*============================================================================================

*======Define TIMES default reporting parameter
*                                               commodity   regionfrom        Vintage info
*                                                  |          |                        /
PARAMETER       TIMESReport(sector,topic,attr,prc,com,all_TS,regFrom,RegTo,milestonyr,vntg,units,cur) "TIMES reporting parameter";
*                                              |                       |
*                                             proces                regionto



*============================================================================================
* 6.1 Reporting (energy system level)
*============================================================================================
*Reporting objective function at regional and obj_items level using information in yearval and g_dyear to set discount year
TIMESReport("ENERGYSYSTEM","dcosts",var_obj_items,"_na","_na","annual",regT,regT,milestonyr,"_na","_na",cur)$(yearval(milestonyr) = g_dyear) = VAR_OBJ_L(regT,var_obj_items,cur);

*We need to correct objsal which currently is represented as a positive number, however, we would like to interpret it as a negative number
TIMESReport("ENERGYSYSTEM","dcosts","objsal","_na","_na","annual",regT,regT,milestonyr,"_na","_na",cur)$(TIMESReport("ENERGYSYSTEM","dcosts","objsal","_na","_na","annual",regT,regT,milestonyr,"_na","_na",cur) > 0) = -1 * TIMESReport("ENERGYSYSTEM","dcosts","objsal","_na","_na","annual",regT,regT,milestonyr,"_na","_na",cur);

*Report time-slice definition as this might be usefull futhere ex post calculations
TIMESReport("ENERGYSYSTEM","inputpar","yrfr","_na","_na",all_TS,regT,regT,milestonyr,"_na","_na","_na")$(yearval(milestonyr) = g_dyear) = G_YRFR(regT, all_TS);

elapsedTIME("report","ENERGYSYSTEM") = TIMEelapsed;

*============================================================================================
* 6.2 Reporting (looping over sectors)
*============================================================================================
PARAMETER ReportInclude(sector)     "Flag: YES if sector is to be included in timesreport loop";

*Include sectors that are part of the times solution
ReportInclude(sector) = 1$sum((prc,reg), prc_gmap(reg,prc,sector));

*Toubleshooting: Test reporting script by only  looping over a single sector 
*ReportInclude(sector) = no; ReportInclude("ELECTRICITY") = yes;

elapsedTIME("start","06Reporting") = TIMEelapsed;
LOOP(sector,
*       Define list of processes associated with sector
        tmp_prc(prc)            = 1$sum(reg, prc_gmap(reg,prc,sector));
*       Define list of input to processes
        tmp_comNRGin(comNRG)    = YES$sum(tmp_prc, topPC(tmp_prc,comNRG,"IN")) +
*       Add commodities associated with trade proceses
                                  YES$sum((tmp_prc,reg,all_reg), top_ire(reg,comNRG,all_reg,comNRG,tmp_prc));
*       Define list of output from processes other than energy service associated with sector
        tmp_comNRGout(comNRG)   = YES$sum(tmp_prc, topPC(tmp_prc,comNRG,"OUT")) +
*       Add commodities associated with trade proceses
                                  YES$sum((tmp_prc,reg,all_reg), top_ire(all_reg,comNRG,reg,comNRG,tmp_prc));
*       Define list of emission input associated with sector
        tmp_comEMISin(comENV)   = YES$sum(tmp_prc, topPC(tmp_prc,comENV,"IN"));
*       Define list of emission output from proces
        tmp_comEMISout(comENV)  = YES$sum(tmp_prc, topPC(tmp_prc,comENV,"OUT"));
*       Define list of material commodity output from proces
        tmp_comMATin(comMAT)    = YES$sum((tmp_prc,reg,all_reg), top_ire(reg,comMAT,all_reg,comMAT,tmp_prc));
*       Define list of material commodity output from proces
        tmp_comMATout(comMAT)   =  YES$sum((tmp_prc,reg,all_reg), top_ire(reg,comMAT,all_reg,comMAT,tmp_prc));
*       Define list of energy service output associated with sector
        tmp_comSrvout(comSrv)   = YES$sum(tmp_prc, topPC(tmp_prc,comSrv,"OUT"));
*       Select all energy saving processes producing energy services
        tmp_prcsav(prc)         = NO;
        tmp_prcsav(tmp_prc)     = YES$SUM(tmp_comSrvout,  1$topPC(tmp_prc,tmp_comSrvout,"OUT"))
                                - YES$SUM(tmp_comNRGin,  1$topPC(tmp_prc,tmp_comNRGin ,"IN"));

*       Define list of tmp_prc that are part of a trade relationship"
        tmp_prctrd(tmp_prc)  =YES$sum((regFrom,tmp_comNRGin,regTo),top_ire(regFrom,tmp_comNRGin,regTo,tmp_comNRGin,tmp_prc));

*display tmp_prc, tmp_comNRGin, tmp_comNRGout, tmp_comEMISout, tmp_comEMISin, tmp_comMATin, tmp_comMATout, tmp_comSrvout;);
*$exit

*       Energy service demand
        TIMESReport(sector,"service","fout",tmp_prc,tmp_comSrvout,all_TS,regT,regT,milestonyr,vntg,units, "_na")
        = F_out(regT,vntg,milestonyr,tmp_prc,tmp_comSrvout,all_TS)$
         com_unit(regT,tmp_comSrvout,units);

*       Energy output
        TIMESReport(sector,"energy","fout" ,tmp_prc,tmp_comNRGout,all_TS,regT,regT,milestonyr,vntg,units,"_na")
        = F_out(regT,vntg,milestonyr,tmp_prc,tmp_comNRGout,all_TS)$
            com_unit(regT,tmp_comNRGout,units);

*       Energy input
        TIMESReport(sector,"energy","f_in" ,tmp_prc,tmp_comNRGin,all_TS,regT,regT,milestonyr,vntg,units,"_na")
        = F_in(regT,vntg,milestonyr,tmp_prc,tmp_comNRGin,all_TS)$
          com_unit(regT,tmp_comNRGin,units);

*       Trade energy (import: regTo)
        TIMESReport(sector,"energy","fout" ,tmp_prc,tmp_comNRGout,all_TS,regFrom,regTo,milestonyr,vntg,units,"_na")$tmp_prctrd(tmp_prc)
        = F_out(regTo,vntg,milestonyr,tmp_prc,tmp_comNRGout,all_TS)$(
                top_ire(regFrom,tmp_comNRGout,regTo,tmp_comNRGout,tmp_prc)
           and  com_unit(regTo,tmp_comNRGout,units));

*       Trade energy (export: regFrom)
        TIMESReport(sector,"energy","f_in" ,tmp_prc,tmp_comNRGin,all_TS,regFrom,regTo,milestonyr,vntg,units,"_na")$tmp_prctrd(tmp_prc)
        = F_in(regFrom,vntg,milestonyr,tmp_prc,tmp_comNRGin,all_TS)$(
                top_ire(regFrom,tmp_comNRGin,regTo,tmp_comNRGin,tmp_prc)
            and com_unit(regFrom,tmp_comNRGin,units));

*       Material output
        TIMESReport(sector,"material","fout" ,tmp_prc,tmp_comMATout,all_TS,regT,regT,milestonyr,vntg,units,"_na")
        = F_out(regT,vntg,milestonyr,tmp_prc,tmp_comMATout,all_TS)$(
               com_unit(regT,tmp_comMATout,units));

*       Material input
        TIMESReport(sector,"material","f_in" ,tmp_prc,tmp_comMATin,all_TS,regT,regT,milestonyr,vntg,units,"_na")
        = F_in(regT,vntg,milestonyr,tmp_prc,tmp_comMATin,all_TS)$(
               com_unit(regT,tmp_comMATin,units));

*       Emission out
        TIMESReport(sector,"emission","fout" ,tmp_prc,tmp_comEMISout,all_TS,regT,regT,milestonyr,vntg,units,"_na")
        = F_out(regT,vntg,milestonyr,tmp_prc,tmp_comEMISout,all_TS)$(
        com_unit(regT,tmp_comEMISout,units));

*       Emission in
        TIMESReport(sector,"emission","f_in" ,tmp_prc,tmp_comEMISin,all_TS,regT,regT,milestonyr,vntg,units,"_na")
        = F_in(regT,vntg,milestonyr,tmp_prc,tmp_comEMISin,all_TS)$(
        com_unit(regT,tmp_comEMISin,units));

*       Marginal price of energy commodity
        TIMESReport(sector,"prices","mpri","_na",tmp_comNRGin,all_ts,regT,regT,milestonyr,"_na",units,cur)
        = par_combalem(regT,milestonyr,tmp_comNRGin,all_ts)$(
                com_unit(regT,tmp_comNRGin,units)
           and  g_rcur(regT,cur));

*       Fuel cost
        TIMESReport(sector,"dcosts","floc" ,tmp_prc,tmp_comNRGin,"ANNUAL",regT,regT,milestonyr,vntg,"_na",cur)
       =(val_flo(regT,vntg,milestonyr,tmp_prc,tmp_comNRGin) + cst_floc(regT,vntg,milestonyr,tmp_prc,tmp_comNRGin))$(
        g_rcur(regT,cur));

*       Fuel taxes
        TIMESReport(sector,"dcosts","flox" ,tmp_prc,tmp_comNRGin,'ANNUAL',regT,regT,milestonyr,vntg,"_na",cur)$
        (cst_flox(regT,vntg,milestonyr,tmp_prc,tmp_comNRGin) ge 0)
       = cst_flox(regT,vntg,milestonyr,tmp_prc,tmp_comNRGin)$(
        g_rcur(regT,cur));

*       Fuel subsidies
        TIMESReport(sector,"dcosts","flos" ,tmp_prc,tmp_comNRGin,'ANNUAL',regT,regT,milestonyr,vntg,"_na",cur)$
        (cst_flox(regT,vntg,milestonyr,tmp_prc,tmp_comNRGin) le 0)
       = cst_flox(regT,vntg,milestonyr,tmp_prc,tmp_comNRGin)$(
        g_rcur(regT,cur));

*       Emission taxes
        TIMESReport(sector,"dcosts","flox" ,tmp_prc,tmp_comEMISout,'ANNUAL',regT,regT,milestonyr,vntg,"_na",cur)$
        (cst_flox(regT,vntg,milestonyr,tmp_prc,tmp_comEMISout) ge 0)
       = cst_flox(regT,vntg,milestonyr,tmp_prc,tmp_comEMISout)$(
        g_rcur(regT,cur));


*       Fixed O&M cost for residential heating technologies million danish kroner (hvordan linker vi fixed cost?)
        TIMESReport(sector,"dcosts","actc" ,tmp_prc,"_na","annual" ,regT,regT,milestonyr,vntg,"_na",cur)
        = cst_actc(regT,vntg,milestonyr,tmp_prc,"-")$(
          g_rcur(regT,cur));

*       Fixed O&M cost for residential heating technologies million danish kroner (hvordan linker vi fixed cost?)
        TIMESReport(sector,"dcosts","fixc" ,tmp_prc,"_na","annual"  ,regT,regT,milestonyr,vntg,"_na",cur)
        = cst_fixc(regT,vntg,milestonyr,tmp_prc)$(
          g_rcur(regT,cur));

*       Fixed O&M taxes
        TIMESReport(sector,"dcosts","fixx" ,tmp_prc,"_na","annual",regT,regT,milestonyr,vntg,"_na",cur)$(cst_fixx(regT,vntg,milestonyr,tmp_prc) ge 0)
        = cst_fixx(regT,vntg,milestonyr,tmp_prc)$(
          g_rcur(regT,cur));

*       Fixed O&M subsidies
        TIMESReport(sector,"dcosts","fixs" ,tmp_prc,"_na","annual",regT,regT,milestonyr,vntg,"_na",cur)$(cst_fixx(regT,vntg,milestonyr,tmp_prc) le 0)
        = cst_fixx(regT,vntg,milestonyr,tmp_prc)$(
          g_rcur(regT,cur));

*       Discounted annual invesment cost
        TIMESReport(sector,"dcosts","invc" ,tmp_prc,"_na","annual",regT,regT,milestonyr,vntg,"_na",cur)
        = cst_invc(regT,vntg,milestonyr,tmp_prc,"INV")$(
          g_rcur(regT,cur));

*       Discounted annual investment taxes
        TIMESReport(sector,"dcosts","invx" ,tmp_prc,"_na","annual",regT,regT,milestonyr,vntg,"_na",cur)$(cst_invx(regT,vntg,milestonyr,tmp_prc,"INV") ge 0)
        = cst_invx(regT,vntg,milestonyr,tmp_prc,"INV")$(
          g_rcur(regT,cur));

*       Discounted annual investment taxes
        TIMESReport(sector,"dcosts","invs" ,tmp_prc,"_na","annual",regT,regT,milestonyr,vntg,"_na",cur)$(cst_invx(regT,vntg,milestonyr,tmp_prc,"INV") le 0)
        = cst_invx(regT,vntg,milestonyr,tmp_prc,"INV")$(
          g_rcur(regT,cur));

*       Average annual lumpsum investment (excluding hurdle rate)
        TIMESReport(sector,"lumpsum","inv_" ,tmp_prc,"_na","annual",regT,regT,milestonyr,vntg,"_na",cur)
        = (cap_new(regT,vntg,tmp_prc,milestonyr,"lumpinv") / periodlength(milestonyr))$(
          g_rcur(regT,cur));

*       Average annual lumpsum investment (including hurdle rate)
        TIMESReport(sector,"lumpsum","invc" ,tmp_prc,"_na","annual",regT,regT,milestonyr,vntg, "_na",cur)
        = ((cap_new(regT,vntg,tmp_prc,milestonyr,"lumpinv")+ cap_new(regT,vntg,tmp_prc,milestonyr,"inv+")) / periodlength(milestonyr))$(
            g_rcur(regT,cur));

*       Average annual lumpsum investment tax 
        TIMESReport(sector,"lumpsum","invx" ,tmp_prc,"_na","annual",regT,regT,milestonyr,vntg,"_na",cur)
        $((cap_new(regT,vntg,tmp_prc,milestonyr,"lumpix") + cap_new(regT,vntg,tmp_prc,milestonyr,"invx+")) ge 0)
        = ((cap_new(regT,vntg,tmp_prc,milestonyr,"lumpix") + cap_new(regT,vntg,tmp_prc,milestonyr,"invx+")) / periodlength(milestonyr))$(
            g_rcur(regT,cur));

*       Average annual lumpsum investment subsidy
        TIMESReport(sector,"lumpsum","invs" ,tmp_prc,"_na","annual",regT,regT,milestonyr,vntg,"_na",cur)
        $((cap_new(regT,vntg,tmp_prc,milestonyr,"lumpix") + cap_new(regT,vntg,tmp_prc,milestonyr,"invx+")) le 0)
        = ((cap_new(regT,vntg,tmp_prc,milestonyr,"lumpix") + cap_new(regT,vntg,tmp_prc,milestonyr,"invx+")) / periodlength(milestonyr))$(
            g_rcur(regT,cur));

*       Total capacity
        TIMESReport(sector,"capacity","cap_" ,tmp_prc,"_na","annual",regT,regT,milestonyr,"_na","capacity_unit","_na")
        =  (par_capl(regT,milestonyr,tmp_prc) + par_pasti(regT,milestonyr,tmp_prc,"0"));

*       Newly installed capacity
        TIMESReport(sector,"capacity","ncap" ,tmp_prc,"_na","annual",regT,regT,milestonyr,"_na","capacity_unit","_na")
        = var_ncap(regT,milestonyr,tmp_prc);

*       Levelised cost of proces
        TIMESReport(sector,"capacity","levc" ,tmp_prc,com,"annual",regT,regT,milestonyr,"_na",units,cur)
        = par_ncapr(regT, milestonyr, tmp_prc, "LEVCOST")$(
                prc_actunt(regT,tmp_prc,com,units)
            and g_rcur(regT,cur));;


elapsedTIME("report",sector) = TIMEelapsed;
countprc("count",sector)     = card(tmp_prc);

);

elapsedTIME("end","06Reporting") = TIMEelapsed;


*============================================================================================
* 7 Test section: Sum check to confirm that TIMES report includes all data
*===========================================================================================
* Currently this section only compares F_IN form the TIMES gdx file with the TIMESreport parameter
* Additional test should be included 

PARAMETERS test_f_in_sum(*) "Simple sum checks to confirm that TIMES report includes all data from F_IN"
	   SumCheck         "Check difference between TIMES gdx and TIMES report "
           tolerance        "Define tolerance for sum chekcs"                           /1e-7/ ;
           
*Sum over data in TIMESgdx
test_f_in_sum("TIMESgdx")    = sum((all_reg,vntg,milestonyr,prc,com,all_TS),F_in(all_reg,vntg,milestonyr,prc,com,all_TS));

*Sum over data in TIMESreport
test_f_in_sum("TIMESreport") = sum((sector,topic,prc,com,all_TS,regFrom,RegTo,milestonyr,vntg,units,cur), TIMESReport(sector,topic,"f_in",prc,com,all_TS,regFrom,RegTo,milestonyr,vntg,units,cur));

* Check difference between TIMES gdx and TIMES report "
SumCheck = ABS(test_f_in_sum("TIMESgdx") - test_f_in_sum("TIMESreport"));

* Abort if test fails
execute$(SumCheck > tolerance) 'msg "%username%" /time:0 Aborted due to difference between data in TIMES gdx and TIMES report script: & /UIzCheck/' ;
ABORT$(SumCheck   > tolerance) "Aborted due to difference between data in TIMES gdx and TIMES report script"


*============================================================================================
* 8 Expanded TIMES reporting (optional) 
*============================================================================================
$ontext
The purpose of this section is to expand the TIMESreport too capture additional dimensions. 
Examples of additional dimensions could be user defined technology_groups,end uses,fuel_groups. Please contact
Energy modelling lab if you want to learn more about how additional dimensions may be added
to the TIMES reporting tool by defining additional user sets in VEDA.
$offtext

*============================================================================================
* 9 Write reporting to gdx and csv
*============================================================================================

*Write timesreport gdx-file including set definitions
execute_unload '%pathTIMESmodel%TIMESReport\GDX\%TIMESscenario%_TIMESreport.gdx' TIMESReport, sector, topic, attr, prc, prc_desc, com, com_desc, all_TS,regT, milestonyr,units,vntg, comSrv;

*Write csv-file based on gdx-file
*$call gdxdump  %pathTIMESmodel%TIMESReport\%TIMESscenario%_TIMESreport.gdx format=csv symb=timesreport output=%pathTIMESmodel%Results\%TIMESscenario%_report.csv noHeader header=sector,topic,attr,process,commodity,timeslice,regionFrom,regionTo,year,vntg,units,currency,value

*Write prc_desc into a csv file
execute 'gdxdump.exe %pathTIMESmodel%TIMESreport\GDX\%TIMESscenario%_TIMESreport.gdx format=csv symb=prc_desc CSVSetText output=%pathTIMESmodel%TIMESreport\prc_desc_timesreport.csv CSVSetText header=region,process,process_desc'

*Write prc_desc into a csv file
execute 'gdxdump.exe %pathTIMESmodel%TIMESreport\GDX\%TIMESscenario%_TIMESreport.gdx format=csv symb=com_desc CSVSetText output=%pathTIMESmodel%TIMESreport\com_desc_timesreport.csv CSVSetText header=region,commodity,commodity_desc'
  
    
    
*Merge existing gdx-files and create csv-file
execute '%pathTIMESmodel%TIMESreport\runMerge_GDX2CSV_TIMESreports.bat';


elapsedTIME("post","8gdxwrite") = TIMEelapsed;

OPTIONS elapsedTIME:1:0:1
display elapsedTIME,countprc;
