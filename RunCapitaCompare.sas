
**************************************************************************************
* Program:      RunCAPITACompare.sas                                                 *
* Description:  Runs each of the policy modules of CAPITA sequentially, for each of  *
*               the 'base' and 'sim' world policy settings (as contained in the      *
*               'Policy' and 'Policy (Sim)' folders in the CAPITA directory) to      *
*               produce the CAPITA_Outfile_Base and CAPITA_Outfile_Sim datasets      *
*               respectively, and the CAPITA_Compare dataset.                        * 
**************************************************************************************;

OPTIONS MINOPERATOR ;

***********************************************************************************
*      1.        Specify year and quarter of interest, period of analysis and     *
*                whether Standard Output is required.                             *
***********************************************************************************;

* Include the DefineCapitaDirectory code to set the main CAPITA drive ;
%INCLUDE "\\CAPITAlocation\DefineCapitaDirectory.sas" ;

* Specify year and quarter of interest ;
%LET Year = 2017 ;      * Format 20XX = 20XX-YY ;       
%LET Quarter = Sep ;    * Valid quarters are Mar Jun Sep Dec ;

* Specify the time duration of analysis ;
* A for Annual, the financial year. This option uses annualised parameters calculated using the time weighted average of each quarter ;
* Q for Quarter. This option uses actual parameter values from the appropriate quarter ;
%LET Duration = A ;

* Specify how to model the removal of the Energy Supplement (ES); 
* G = Choose to model the grandfathering of ES - option not available in public release version; 
* Y = Choose to give everyone the ES; 
* N = Choose to give noone the ES; 
%LET RunEs = Y; 

* Specify whether to run StandardOutput.sas ;
* Standard Output produces tables summarising differences between base and sim runs
  from RunCapitaCompare and can export to pre-formatted Excel Tables if required. ;
* Note that by default this will NOT run if Cameo Output is produced. ;
* Y to produce StandardOutput ;

%LET RunStandardOutput = Y ;
%LET SOFolder = &CapitaDirectory.Standard Output\ ;

* Specify whether the results are to be output to Excel or just basic sas output ;
* Y for linked Excel workbook ;

%LET ExcelOut = Y ;

* Calculate relevant date flag, depending on Annual or Quarter run, and ES flag when specified in cameo code ;
%GLOBAL DateFlag RunCameo RunBenchmarkFlag ;
%MACRO DateFlagandEs ;
    /* Specify Year for Cameo run */
    %IF &RunCameo = Y %THEN %DO ;
        %LET Year = &CameoYear ;
        %LET Quarter = &CameoQuarter ;
        %LET Duration = &CameoDuration ;
        %LET RunEs = &CameoRunEs ; 
    %END ;

    /* Calculate relevant date flag, depending on Annual or Quarter run */
    %IF &Duration = A %THEN %LET DateFlag = "1Jul&year."d ;
    %ELSE %IF &Duration = Q %THEN %LET DateFlag = "1&Quarter&Year."d ;
%MEND DateFlagandEs ;
%DateFlagandEs

***********************************************************************************
*      2.         Specify basefiles                                               *
*                                                                                 *
**********************************************************************************;
* &RunCameo is specified in the RunCameo for a Cameo run. ;
* &CompareType specifies 'Policy' for comparison of base and sim world policies on same basefile, 
  and 'Version' for comparing two different versions of the basefile. ;
%LET CompareType = Policy ;
%GLOBAL RunCameo Basefile ;

* Set Basefile directory. Sets the correct basefile used e.g. CAPITA basefile or Cameo basefile ;
%MACRO BasefileDir ;
    /* Specify name of Basefile for Cameo run */
    %IF &RunCameo = Y %THEN %DO ;
        %LET Basefile = Capita_InputFile ;
        %LET Work = %SYSFUNC( GETOPTION( Work ) ) ;
        LIBNAME Basefile "&Work" ;
    %END ;

    /* Specify name of Basefile for standard run */
    %ELSE %DO ;
        %LET Basefile = Basefile&Year ;
        LIBNAME Basefile "&CapitaDirectory.Basefiles" ;
        %IF &CompareType = Version %THEN %DO ;
            LIBNAME Simfile "&CapitaDirectory.Basefiles\New Basefiles" ; 
        %END ;
    %END ;
%MEND BasefileDir ;

%BasefileDir

***********************************************************************************
*      3.        Specify location of master parameters data set                   *
*                                                                                 *
***********************************************************************************

* Specify location of master parameters data set. One for quarter and one for annual ;
* Parameters should be generated first in a separate process ;
%LET ParmBaseDrive = &CapitaDirectory.Parameter\ ;
LIBNAME ParmQB "&ParmBaseDrive.Quarter" ;
LIBNAME ParmAB "&ParmBaseDrive.Annual" ;

* Specify location of master parameters data set. One for quarter and one for annual ;
* Parameters should be generated first in a separate process ;
%LET ParmSimDrive = &CapitaDirectory.Parameter\ ;
LIBNAME ParmQS "&ParmSimDrive.Quarter" ;
LIBNAME ParmAS "&ParmSimDrive.Annual" ;

* Make simulated world parameter changes, or insert new parameters here;
%MACRO ParamChange ;

    /* Make any parameter changes here. Alternatively these changes can be made in the CPS */    

%MEND ParamChange ;

***********************************************************************************
*      4.        Specify locations of policy modules                              *
*                                                                                 *
**********************************************************************************;

* Specify common directory for BASE and SIMULATED policy worlds ;
%LET PolicyBase = &CapitaDirectory.Policy Modules\ ;
%LET PolicySim  = &CapitaDirectory.Policy Modules\ ;

* Additional code for Module 11 ;
%LET SaptoRebThres         = &PolicyBase.SaptoRebThres.sas ;            

* Specify name of base world policy modules ;
%LET Initialisation_Base   = &PolicyBase.1 Initialisation.sas ;           * Module 1 - Initialisation ;
%LET Income1_Base          = &PolicyBase.2 Income1.sas ;                  * Module 2 - Income 1 ;
%LET Dependants1_Base      = &PolicyBase.3 Dependants1.sas ;              * Module 3 - Dependants 1 ;
%LET DVA_Base              = &PolicyBase.4 DVA.sas ;                      * Module 4 - DVA payments ;
%LET Pension_Base          = &PolicyBase.5 Pensions.sas ;                 * Module 5 - Pension payments ;
%LET Allowance_Base        = &PolicyBase.6 Allowance.sas ;                * Module 6 - Allowance payments ;
%LET Income2_Base          = &PolicyBase.7 Income2.sas ;                  * Module 7 - Income 2 ;
%LET Dependants2_Base      = &PolicyBase.8 Dependants2.sas ;              * Module 8 - Dependants 2 ;
%LET FTB_Base              = &PolicyBase.9 FTB.sas ;                      * Module 9 - Family payments ;
%LET Supplement_Base       = &PolicyBase.10 Supplements.sas ;             * Module 10 - Supplements ;
%LET Tax_Base              = &PolicyBase.11 Tax.sas ;                     * Module 11 - Taxation ;
%LET Childcare_Base        = &PolicyBase.12 Childcare.sas ;               * Module 12 - Childcare ;
%LET Finalisation_Base     = &PolicyBase.13 Finalisation.sas ;            * Module 13 - Finalisation ;
 
* Specify name of simulated world policy modules ;
%LET Initialisation_Sim   = &PolicySim.1 Initialisation.sas ;           * Module 1 - Initialisation ;
%LET Income1_Sim          = &PolicySim.2 Income1.sas ;                  * Module 2 - Income 1 ;
%LET Dependants1_Sim      = &PolicySim.3 Dependants1.sas ;              * Module 3 - Dependants 1 ;
%LET DVA_Sim              = &PolicySim.4 DVA.sas ;                      * Module 4 - DVA payments ;
%LET Pension_Sim          = &PolicySim.5 Pensions.sas ;                 * Module 5 - Pension payments ;
%LET Allowance_Sim        = &PolicySim.6 Allowance.sas ;                * Module 6 - Allowance payments ;
%LET Income2_Sim          = &PolicySim.7 Income2.sas ;                  * Module 7 - Income 2 ;
%LET Dependants2_Sim      = &PolicySim.8 Dependants2.sas ;              * Module 8 - Dependants 2 ;
%LET FTB_Sim              = &PolicySim.9 FTB.sas ;                      * Module 9 - Family payments ;
%LET Supplement_Sim       = &PolicySim.10 Supplements.sas ;             * Module 10 - Supplements ;
%LET Tax_Sim              = &PolicySim.11 Tax.sas ;                     * Module 11 - Taxation ;
%LET Childcare_Sim        = &PolicySim.12 Childcare.sas ;               * Module 12 - Childcare ;
%LET Finalisation_Sim     = &PolicySim.13 Finalisation.sas ;            * Module 13 - Finalisation ;

***********************************************************************************
*      5.        Read in parameters for the specified date and period             *
*                                                                                 *
**********************************************************************************;

* Parameters for the specified date and period are read in from the master parameters data set ;

%MACRO Param( Duration , BaseOrSim ) ;

    DATA Parm&Duration&BaseOrSim ;

        /* Read in quarterly parameters */
        %IF %UPCASE( &Duration ) = Q %THEN %DO ;
            SET Parm&Duration&BaseOrSim..AllParams_Q ;
/*			SET Parm&Duration&BaseOrSim..ProbGrndfthr_Q ;*/ 
        %END ;

        /* Read in annualised parameters */
        %ELSE %IF %UPCASE( &Duration ) = A %THEN %DO ;
            SET Parm&Duration&BaseOrSim..AllParams_A ;
/*			SET Parm&Duration&BaseOrSim..ProbGrndfthr_A ;*/
        %END ;

        /* Read in parameters from the chosen period */
        IF Date <= &DateFlag < Enddate ;

        /* Add or replace parameters in this data step */
        %IF &BaseOrSim = S %THEN %DO ;
            %ParamChange
        %END ;

    RUN ;

%MEND Param ;

%Param( &Duration , B )
%Param( &Duration , S )

***********************************************************************************
*      6.        Run policy modules                                               *
*                                                                                 *
**********************************************************************************;

* Include SAPTO function - additional code for module 11; 

%MACRO DefineSaptoFunction ;

%IF %SYMEXIST(SaptoFuncDefined) %THEN %DO ;
	%LET SaptoFuncDefined = 1 ;
%END ;

%ELSE %DO ;
	%INCLUDE "&SaptoRebThres" ;              
	%GLOBAL SaptoFuncDefined ;
%END ;

%MEND DefineSaptoFunction ;

%DefineSaptoFunction ;       
 
* Run policy modules in a data step ;
%MACRO Outfile( BasefileLib , OutfileName , PolicySfx , ParmSfx ) ;
 
    DATA &OutfileName ;

        * Switch off log printing options to return log options back to default ;
        OPTIONS MINOPERATOR NOMFILE NOMPRINT NOSOURCE2 ;

        * Read in parameters ;
        IF _N_ = 1 THEN SET Parm&Duration&ParmSfx ;

        * Read in basefile ;
        %IF &RunCameo = Y %THEN %LET Basefile = Capita_InputFile ;

        SET &BasefileLib..&Basefile ;

        BY FamId ;

        * Include and run code for each base world policy modules ;

        %INCLUDE "&&Initialisation&PolicySfx" ;  
        %INCLUDE "&&Income1&PolicySfx" ;      
        %INCLUDE "&&Dependants1&PolicySfx" ;                   
        %INCLUDE "&&Dva&PolicySfx" ;                          
        %INCLUDE "&&Pension&PolicySfx" ;                       
        %INCLUDE "&&Allowance&PolicySfx" ;                    
        %INCLUDE "&&Income2&PolicySfx" ;                        
        %INCLUDE "&&Dependants2&PolicySfx" ;                    
        %INCLUDE "&&FTB&PolicySfx" ;                           
        %INCLUDE "&&Supplement&PolicySfx" ;                     
        %INCLUDE "&&Tax&PolicySfx" ;   
        %IF &RunCameo = Y %THEN %DO ;            
            %INCLUDE "&&Childcare&PolicySfx" ; 
        %END ;  
        %INCLUDE "&&Finalisation&PolicySfx" ;
    
    RUN ;

%MEND Outfile ;

***********************************************************************************
*      7.        Combine base and simulated policy outfiles                       *
*                                                                                 *
**********************************************************************************;

* Rename all variables. Append &Sfx to the end of each variable ;

%MACRO RenameVar( Outfile , Sfx ) ;

    * Create dataset containing list of all variable names ;
    PROC CONTENTS 
        DATA = &Outfile 
        OUT = VarNames
        ( KEEP = NAME ) 
        NOPRINT ; 
    RUN ;

    * Create temporary dataset that writes the variable rename list to a .txt file ;
    DATA _NULL_ ;
        SET VarNames
        ( WHERE = ( UPCASE( NAME ) NOT IN( 'FAMID' ) ) )
        END = EOF ;

        FILENAME Rename "&PolicyBase\Rename.txt" ;
        FILE Rename ;

        NewName = TRIM( NAME ) || "&Sfx" ;
        IF _N_ = 1 THEN PUT 'RENAME' ;
        IF Name NE NewName THEN PUT Name ' = ' NewName ;
        IF EOF THEN PUT ';' ;
    RUN ;

    * Read in .txt file containing the variable rename list ;
    DATA &Outfile ;
        SET &Outfile ;
        %INCLUDE Rename ;
    RUN ;

%MEND RenameVar ;

* Merge two different Outfiles ;

%MACRO Merge( Outfile1 , Outfile2 ) ;

    DATA CAPITA_Compare ;
        MERGE &Outfile1 &Outfile2 ;
        BY FamID ;
    RUN ;

%MEND Merge ;

***********************************************************************************
*      8.        Execute Steps 6 and 7 according to type of comparison run        *
*                                                                                 *
**********************************************************************************;

* Run required type of comparison. ;
%MACRO CompareType ;
    /* Run 'Policy' comparison */
    %IF &CompareType = Policy %THEN %DO ;
        %Outfile( Basefile , CAPITA_Outfile_Base , _Base , B )
        %Outfile( Basefile , CAPITA_Outfile_Sim , _Sim , S )
        %RenameVar( CAPITA_Outfile_Base , _Base )
        %RenameVar( CAPITA_Outfile_Sim , _Sim )
        %Merge( CAPITA_Outfile_Base , CAPITA_Outfile_Sim )
    %END ;

    /* Run 'Version' comparison */
    %ELSE %IF &CompareType = Version %THEN %DO ;
        %Outfile( Basefile , CAPITA_Outfile_Base , _Base , B )
        %Outfile( Simfile , CAPITA_Outfile_Sim , _Base , B )
        %RenameVar( CAPITA_Outfile_Base , _Base )
        %RenameVar( CAPITA_Outfile_Sim , _Sim )
        %Merge( CAPITA_Outfile_Base , CAPITA_Outfile_Sim )
    %END ;
%MEND CompareType ;

* Call %CompareType ;
%CompareType 

***********************************************************************************
*      9.        Produce Standard Output if required.                             *
*                                                                                 *
**********************************************************************************;

%MACRO RunStandardOutput ;
    * Calls the Standard Output module ;

    %IF &RunCameo NE Y %THEN %DO ;
    * Do not produce Standard Output during a cameo comparison run. ;
        %IF &RunStandardOutput = Y %THEN %DO ;
            %INCLUDE "&SOFolder.StandardOutput.sas" ;
        %END ;
    %END ; 

%MEND RunStandardOutput ;

%RunStandardOutput

%SYMDEL RunCameo ;
