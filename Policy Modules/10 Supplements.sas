
**************************************************************************************
* Program:      10 Supplements.sas                                                   *
* Description:  Calculates entitlements to the supplements administered by the       * 
*               Department of Social Services (DSS)                                  *
**************************************************************************************;

***********************************************************************************
*   Macro:   RunSupplements                                                       *
*   Purpose: Coordinate calculation                                     		  *
**********************************************************************************;;

%MACRO RunSupplements ;

    ***********************************************************************************
    *      1.        Carer Allowance                                                  *
    **********************************************************************************;

    * Determine eligibility for and assign rate of Carer Allowance ;

    %CarerAllowance( r )

    IF Coupleu = 1 THEN DO ; 

        %CarerAllowance( s )

    END ; 

    ***********************************************************************************
    *      2.        Carer Supplement                                                 *
    **********************************************************************************;

    * Determine eligibility for and assign rate of Carer Supplement ;

    %CarerSupplement( r , s )

    IF Coupleu = 1 THEN DO ; 

        %CarerSupplement( s , r )

    END ; 

    ***********************************************************************************
    *      3.        Income Support Bonus (before 31 December 2016)                   *
    **********************************************************************************;

    * Determine eligibility for and assign rate of Income Support Bonus ;

    %IncSupBon( r )

    IF Coupleu = 1 THEN DO ; 

        %IncSupBon( s )

    END ; 

    ***********************************************************************************
    *      4.        Commonwealth Seniors Health Card                                 *
    **********************************************************************************;

    %CwthSenHlthCard( r )

    IF Coupleu = 1 THEN DO ; 

        %CwthSenHlthCard( s )

    END ; 

    ***********************************************************************************
    *      5.        Seniors Supplement (before 30 June 2015)                         *
    **********************************************************************************;

    * Determine eligibility for and assign rate of Seniors Supplement ;

    %SeniorSupplement( r )

    IF Coupleu = 1 THEN DO ; 

        %SeniorSupplement( s )

    END ; 

    ***********************************************************************************
    *      6.        Pensioner Education Supplement                                   *
    **********************************************************************************;

    * Determine eligibility for and assign rate of Pensioner Education Supplement ;
    %PenEdSup( r , s )

    IF Coupleu = 1 THEN DO ; 

        %PenEdSup( s , r )

    END ; 
    ***********************************************************************************
    *      7.        Telephone Allowance                                              *
    **********************************************************************************;

    * Determine eligibility for Telephone Allowance ;

    %TelephoneAllElig( r , s )

    IF Coupleu = 1 THEN DO ; 

        %TelephoneAllElig( s , r )

    END ; 

    * Assign rate of Telephone Allowance ;
    IF TelAllLowFlagr = 1 OR TelAllHighFlagr = 1 THEN DO ;

        %TelephoneAllRate( r , s )

    END ; 

    IF Coupleu = 1 THEN DO ; 

        IF TelAllLowFlags = 1 OR TelAllHighFlags = 1 THEN DO ;

            %TelephoneAllRate( s , r )

        END ;

    END ; 
        
    ***********************************************************************************
    *      8.        Utilities Allowance                                              *
    **********************************************************************************;

    * Determine eligibility for and assign rate of Utilities Allowance ;

    %UtilitiesAll( r )

    IF Coupleu = 1 THEN DO ;

        %UtilitiesAll( s )

    END ; 

    ***********************************************************************************
    *      9.        Single Income Family Supplement (before 1 July 2017)             *
    **********************************************************************************;

    * Determine eligibility for and assign rate of Single Income Family Supplement ;

    %SinIncFamSup( r , s )

    * Only check if the spouse is eligible for SIFS if the reference person is in a 
      couple and the reference person does not receive SIFS.  This is because only
      one member of a couple (the primary income earner) can be eligible for SIFS ;
    IF Coupleu = 1 AND SifsFlag = 0 THEN DO ; 

        %SinIncFamSup( s , r )

    END ; 

    ***********************************************************************************
    *      10.        Construct Supplements Aggregates                                *
    **********************************************************************************;

    %SupplementsAggregates( r )

    IF Coupleu = 1 THEN DO ; 

        %SupplementsAggregates( s )

    END ;              

%MEND RunSupplements ;

**********************************************************************************
*   Macro:   CarerAllowance                                                      *
*   Purpose: Determine eligibility for and assign rate of Carer Allowance.       *
*********************************************************************************;;

%MACRO CarerAllowance( psn ) ;

    * Determine eligibility for Carer Allowance ;
    IF PenType&psn = 'CARER'         /* Receives Carer Payment */
    OR CarerAllSW&psn > 0            /* Receives Carer Allowance on the SIH */
    THEN DO ;

    * Assign rate of Carer Allowance ;
    * A person receives an allotment of Carer Allowance for each person cared for.
      This is imputed in the CAPITA basefile based off the amount of Carer Allowance
      received in the SIH. ;
        CareAllF&psn = NumCareDeps&psn * CareAllMaxF ;
        CareAllA&psn = CareAllF&psn * 26 ; 
        IF CareAllF&psn > 0 THEN CareAllFlag&psn = 1 ;
    END ;

%MEND CarerAllowance ;

**********************************************************************************
*   Macro:   CarerSupplement                                                     *
*   Purpose: Determine eligibility for and assign rate of Carer Supplement.      *
*********************************************************************************;;

%MACRO CarerSupplement( psn , partner ) ;

    * Determine eligibility for Carer Supplement ;
    * Do not include eligibility for DVA Carer Service Pensioner as cannot be 
      modelled. ; 
    * An individual is eligible to receive a Carer Supplement for each one of Carer 
      Payment, Wife Pension or DVA Partner Service Pension a person receives. That 
      person will also receive a Carer Supplement for each care receiver that person
      receives a Carer Allowance payment for. ;

    * For each care receiver for whom Carer Allowance is paid ;
    IF CareAllFlag&psn = 1 THEN NumCareSup&psn = NumCareSup&psn + NumCareDeps&psn ;

    * Add one Carer Supplement for those receiving Carer Payment ;
    IF PenType&psn = 'CARER' THEN NumCareSup&psn = NumCareSup&psn + 1 ;
    
    * Add one Carer Supplement for those receiving Wife Pension with Carer Allowance ;
    IF PenType&psn = 'WIFE' 
    AND CareAllFlag&psn = 1 

        THEN NumCareSup&psn = NumCareSup&psn + 1 ;

    * Add one Carer Supplement for those receiving DVA Partner Service Pension (for looking after a DVA Service
    Pensioner recipient) and who is also receiving Carer Allowance. ;
    IF  DvaType&psn     = 'SERVICE' 
    AND DvaType&partner = 'SERVICE' 
    AND CareAllFlag&psn = 1 

        THEN NumCareSup&psn = NumCareSup&psn + 1 ;

    * Assign rate of Carer Supplement ;
    IF NumCareSup&psn > 0 THEN DO ;

        * Total amount of carer supplement is equal to the Carer Supplement rate
        multiplied by the number of carer supplements an individual is eligible
        for. ;
        CareSupA&psn = NumCareSup&psn * CareSupMaxA ; 

        CareSupF&psn = CareSupA&psn / 26 ;

    END ;

%MEND CarerSupplement ;

**********************************************************************************
*   Macro:   IncSupBon                                                           *
*   Purpose: Determine eligibility for and assign rate of Income Support Bonus.  *
*********************************************************************************;;
%MACRO IncSupBon( psn ) ;

    * Eligibility;
    * aged under Age Pension age ;
    IF ( ( Sex&psn = 'F' AND ActualAge&psn < FemaleAgePenAge )         
      OR ( Sex&psn = 'M' AND ActualAge&psn < MaleAgePenAge ) )
    /* receiving either Newstart Allowance, Youth Allowance, Parenting Payment,
      Sickness Allowance, Austudy, Special Benefit or Abstudy */
    AND ( AllowType&psn IN ( 'NSA' , 'YASTUD' , 'YAOTHER' , 'PPP' , 'SICK' , 'AUSTUDY' , 'SPB' , 'ABSTUDY' ) 
      OR PenType&psn = 'PPS' )

        THEN IncSupBonFlag&psn = 1 ;

     * Rate ;

    IF IncSupBonFlag&psn = 1 THEN DO ;

    * Singles. Convert from Bi-annual to fornightly amount ;

        IF Coupleu = 0 THEN IncSupBonF&psn = IncSupBonMaxBs / 13 ; 

        * Couples. Convert from Bi-annual to fornightly amount ;
        ELSE IF Coupleu = 1 THEN IncSupBonF&psn = IncSupBonMaxBc / 13 ; 

        IncSupBonA&psn = IncSupBonF&psn * 26 ;

    END ;

%MEND IncSupBon ;

**********************************************************************************
*   Macro:   CwthSenHlthCard                                                     *
*   Purpose: Determine eligibility for the Commonwealth Seniors Health Card.     *
*********************************************************************************;;

%MACRO CwthSenHlthCard( psn ) ;

    * Eligibility for Commonwealth Seniors Health Card (CSHC) ;
    IF ( ( Sex&psn = 'F' AND ActualAge&psn >= FemaleAgePenAge )     /* Person is of */      
      OR ( Sex&psn = 'M' AND ActualAge&psn >= MaleAgePenAge   ) )   /* age pension age  */
    AND PenType&psn     = ''                     /* Not receiving DSS Pension*/                            
    AND AllowType&psn   = ''                     /* Not receiving DSS allowance*/ 
    AND DvaType&psn NOT IN ( 'SERVICE' )         /* Not receiving DVA Service Pension*/
    THEN DO ;

        * Singles entitlement ;

        IF Coupleu = 0 THEN DO ; 

            * Income under payment threshold ;
            IF AdjTaxIncA&psn < CshcThrAS + DepsSec5 * CshcThrDepAddA THEN DO ; 

                * Flag eligibility for CSHC (used for TAL) ;
                CshcFlag&psn = 1 ;              

            END ;
                
        END ; * End singles ;

        * Couples entitlement ;
        ELSE IF Coupleu = 1 THEN DO ; 

            * Income under payment threshold ;
            IF ( AdjTaxIncAr + AdjTaxIncAs ) / 2 < CshcThrAC + DepsSec5 * CshcThrDepAddA THEN DO ; 

                * Flag eligilibty for CSHC (used for TAL) ;
                CshcFlag&psn = 1 ;      

            END ;
            
        END ; * End Couples ;

    END ;    * End eligible for Seniors Supplement ;

%MEND CwthSenHlthCard ;

**********************************************************************************
*   Macro:   SeniorSupplement                                                    *
*   Purpose: Determine eligibility for and assign rate of Seniors Supplement.    *
*********************************************************************************;;

%MACRO SeniorSupplement( psn ) ;

    * Legislation abolishing Senior Supplement was passed on 22 June 2015. 
      Zeroed off in CPS from 1 July 2015;

        * Eligibility for Senior Supplement depends on eligibility for Commonwealth Seniors Health Card (CSHC) ;

        * Singles entitlement ;

        IF Coupleu = 0 
        AND CshcFlag&psn = 1
        THEN DO ; 

            * CSHC recipients continue to receive Senior Supplement ES after Senior Supplement ceases ;                 
            * Senior Supplement ceases from 1 July 2015 ;
            SenSupFlag&psn = 1 ;            /* Flag Senior Supplement eligibility */
            SenSupQ&psn = SenSupMaxAS / 4 ; /* Convert from annual to quarterly amount */
			

			*Assign Energy Supplement for singles based on grandfathering test; 
			*Cease Energy Supplement for new CSHC claimants from 20 March 2017. 
			Budget Savings Omnibus Bill 2016 legislated September 2016.;

			%IF (&Duration = A AND &Year >= 2017) 
			    OR (&Duration = Q AND &Year > 2017) 	
			    OR (&Duration = Q AND &Year = 2017 AND (&Quarter = Jun OR &Quarter = Sep OR &Quarter = Dec) ) 
			%THEN %DO ;

				%IF &RunEs = G %THEN %DO ; 

					IF PenType&psn IN ('AGE') THEN DO ;
						IF RandAgeEsGfth&psn < AgeEsGfthrProb THEN SenSupEsF&psn = SenSupEsMaxFS ;
						ELSE  SenSupEsF&psn = 0;
					END; 

				%END;  

				%ELSE %IF &RunEs = Y %THEN %DO ; 

					SenSupEsF&psn = SenSupEsMaxFS ;  

				%END; 

				%ELSE %IF &RunEs = N %THEN %DO ; 

					SenSupEsF&psn = 0 ; 

				%END; 

			%END; 

			/*End*/
			%ELSE %DO; 
				SenSupEsF&psn = SenSupEsMaxFS ;  
			%END ;
               
        END ; * End singles ;

		

        * Couples entitlement ;

        ELSE IF Coupleu = 1 
        AND CshcFlag&psn = 1
        THEN DO ; 

            * CSHC recipients continue to receive Senior Supplement ES after Senior Supplement ceases ;                 
            * Senior Supplement ceases from 1 July 2015 ;
            SenSupFlag&psn = 1 ;            /*  Flag Senior Supplement eligibility */
            SenSupQ&psn = SenSupMaxAC / 4 ; /*  Convert from annual to quarterly amount */

			*Assign Energy Supplement for couples based on grandfathering test; 
			*Cease Energy Supplement for new CSHC claimants from 20 March 2017. 
			Budget Savings Omnibus Bill 2016 legislated September 2016.;

			%IF (&Duration = A AND &Year >= 2017) 
			    OR (&Duration = Q AND &Year > 2017) 	
			    OR (&Duration = Q AND &Year = 2017 AND (&Quarter = Jun OR &Quarter = Sep OR &Quarter = Dec) ) 
			%THEN %DO ;
		

				%IF &RunEs = G %THEN %DO ; 

					IF PenType&psn IN ('AGE') THEN DO ;
						IF RandAgeEsGfth&psn < AgeEsGfthrProb THEN SenSupEsF&psn = SenSupEsMaxFC ;
						ELSE  SenSupEsF&psn = 0;
					END; 

				%END; 

				%ELSE %IF &RunEs = Y %THEN %DO ; 

					SenSupEsF&psn = SenSupEsMaxFC ; 

				%END; 

				%ELSE %IF &RunEs = N %THEN %DO ; 

					SenSupEsF&psn = 0 ; 

				%END; 

			%END; 
			/*End*/

			%ELSE %DO; 

				SenSupEsF&psn = SenSupEsMaxFC ; 

			%END ;

        END ; * End Couples ;

        SenSupA&psn = SenSupQ&psn * 4 ;
        SenSupF&psn = SenSupQ&psn / 6.5 ;
        SenSupEsA&psn = SenSupEsF&psn * 26 ;
        SenSupTotF&psn = SenSupF&psn + SenSupEsF&psn ;
        SenSupTotA&psn = SenSupTotF&psn * 26 ;

%MEND SeniorSupplement ;

**********************************************************************************
*   Macro:   PenEdSup                                                            *
*   Purpose: Determine eligibility for and assign rate of Pensioner Education    *
*            Supplement.                                                         *
*********************************************************************************;;

%MACRO PenEdSup( psn , partner ) ;

    * This code does not assign PES to DVA ISS recipients. ;

        * Payments for eligibilty from SSA 1991 1061PJ. ;
        IF ActualAge&psn >= MinPesAge     /* At least as old as the minimum PES age */
            AND ( ( StudyType&psn IN ( 'FTNS' , 'SS' )          /* Studying full-time */
            /*Receives Disability Support Pension, Carer Payment or Parenting Payment Single*/
                AND ( PenType&psn IN ( 'DSP' , 'DSPU21' , 'CARER' , 'PPS' ) 
            /* Invalid Service Pension proxied through DVA Service Pension and under DVA    */
            /* Pension Age*/
                OR ( DvaType&psn = 'SERVICE' AND ActualAge&psn < DvaPenAge ) 
            /* Receives Wife Pension for a partner receiving DSP                            */
                OR ( PenType&psn = 'WIFE'    AND PenType&partner = 'DSP' )
            /* Receives Widow Allowance */
                OR ( AllowType&psn = 'WIDOW' ) 
            /* Receives NSA and is a single principal carer */
                OR ( AllowType&psn = 'NSA' AND SingPrinCareFlag = 1 ) ) )         
            /* Studying part-time */
            OR ( StudyType&psn IN ( 'PTNS' )                  
            /*Receives Disability Support Pension, Carer Payment or Parenting Payment Single*/
                AND ( PenType&psn IN ( 'DSP' , 'DSPU21' , 'CARER' , 'PPS' )
            /* Invalid Service Pension proxied through DVA Service Pension and under DVA    */
            /* Pension Age*/
                OR ( DvaType&psn = 'SERVICE' AND ActualAge&psn < DvaPenAge )
            /* Receives Special Benefit and is a sole parent             */
                OR ( AllowType&psn IN ( 'SPB' ) AND AllowSubType&psn = 'SingDeps')
            /* Receives Widow Allowance             */
                OR AllowType&psn = 'WIDOW' 
            /* DVA Partner Service Pension receipient whose partner receives DVA Invalidity Service Pension. */
                OR ( DvaType&psn = 'SERVICE' 
                   AND DvaType&partner = 'SERVICE' 
                   AND ActualAge&partner < DvaPenAge )
            /* Receives DVA War Widow OR DVA Disability Pension and has dependent children */
                OR ( DvaType&psn IN ( 'WARWID' , 'DVADIS' ) AND DepsSec5 > 0 ) ) ) )     

            THEN PenEdSupFlag&psn = 1 ;

        * Determine rate of Pensioner Education Supplement the individual is eligible for and assign that rate ;
			* In CAPITA, the PES is assigned in full to those studying full-time on the SIH (>=75% study load) and 
			assigned in half to those studying part-time on the SIH(<75% study load). 
			* This is slightly different to the current policy (as at 2017-18 Budget) whereby the rate of PES is aligned with study loads, as 
			per the 2017-18 Budget. That is, 0-25% study load = 0% PES,25% study load = 25% PES, 26-50% study load = 50% PES,
			51-75% study load = 75% PES, 76-100% study load = 100% PES. 
			* Data limitations are the primary reason for this simplified approach, which will continue to be revisited in 
			future versions of CAPITA;  

        IF PenEdSupFlag&psn = 1 THEN DO ; * Eligible for PES ;

            IF StudyType&psn = 'PTNS'  THEN DO ;

                PenEdSupF&psn = PenEdSupHalfMaxF ;

            END ;

            * Everyone else gets the full rate of PES ;
            ELSE PenEdSupF&psn = PenEdSupFullMaxF ; 
            
			
			%IF (&Duration = A AND &Year  < 2018 
		    	OR &Duration = Q AND &Year < 2018) 	
		    %THEN %DO ;

				*Annual payment; 
	            PenEdSupA&psn = PenEdSupF&psn * 26 ;

			%END; 

			%ELSE %DO; 

				*2017-18 Budget - PES is only paid during study periods after 1 Jan 2018 (assume start 1 July 2018), consistent with DSS this is approximated to be 21 out of 26 fortnights; 
	            PenEdSupA&psn = PenEdSupF&psn * 21 ;

			%END; 

        END ;   
 

%MEND PenEdSup ;

**********************************************************************************
*   Macro:   TelephoneAllElig                                                    *
*   Purpose: Determine eligibility and entitlement for Telephone Allowance.      *
*********************************************************************************;;
%MACRO TelephoneAllElig( psn , partner ) ;

    * Eligibility - SSA 1991 1061Q;

    * (1) - Receipt of DSS Pension. NOTE. s1061R(a) A person who receives more 
            than the basic amount of Pension Supplement is not eligible for Tel
            All as they will receive it as part of their Pension Supplement. ;
    IF Pentype&psn NOT IN ( '' ) 
    AND PenSupMinF&psn = 0 

        THEN TelAllFlag&psn = 1 ; 

    * (2, 2A) - Receipt of YA Other or NSA, partial capacity to work (not modelled) 
                or single principal carer (modelled). ;
    IF AllowType&psn IN ( 'YAOTHER' , 'NSA' )
    AND SingPrinCareFlag = 1 

        THEN TelAllFlag&psn = 1 ;

    * (2B) - Receipt of YA Other or NSA, couple principal carer, partner is
             receiving NSA or Sickness Allowance and is at least 60 years of age
             and has been receiving a social security payment for at least 9
             months. NOT MODELLED;

    * (2C, 2D) - not modelled ;

    * (3) - Receiving Widow Allowance, NSA, Sickness Allowance, Partner Allowance
            PPP or Special Benefit, is at least 60 years of age and has been 
            receiving a social security payment for at least 9 months. ; 
    IF AllowType&psn IN ( 'WIDOW' , 'NSA' , 'SICK' , 'PARTNER' , 'PPP' , 'SPB' )
    AND AllowSubType&psn = 'OLDLTR' 

        THEN TelAllFlag&psn = 1 ;

    * (3A) - Receiving Partner Allowance or PPP, partner is
             receiving NSA or Sickness Allowance and is at least 60 years of age
             and has been receiving a social security payment for at least 9
             months. ;
    IF AllowType&psn IN ( 'PARTNER' , 'PPP' )
    AND AllowType&partner IN ( 'NSA' , 'SICK' ) 
    AND AllowSubType&partner = 'OLDLTR' 

        THEN TelAllFlag&psn = 1 ;

    * (3B) - Not modelled ;

    * (4A) - Eligible for the Commonwealth Seniors Health Card. ;
    * All those who receive the CSHC already receive an amount equivalent to the Telephone Allowance
      as part of their Senior Supplement payment. Therefore, Senior Supplement recipients are
      excluded from receiving Telephone Allowance. S1061R(d) SSA 1991 ;
    IF SenSupFlag&psn = 1 THEN TelAllFlag&psn = 0 ;

    * Assign flags for high or low rate of Tel All. Eligibility for higher rate is
      from s1061SB. ;
    IF TelAllFlag&psn = 1 THEN DO ;

        IF PenType&psn = 'DSPU21' 
        OR CshcFlag&psn = 1 
            THEN TelAllHighFlag&psn = 1 ;
   
        ELSE TelAllLowFlag&psn = 1 ;

    END ;

%MEND TelephoneAllElig ;

**********************************************************************************
*   Macro:   TelephoneAllRate                                                    *
*   Purpose: Assign rate of Telephone Allowance.                                 *
*********************************************************************************;;
%MACRO TelephoneAllRate( psn , partner ) ;

    * Assign rate of Telephone Allowance for those eligible for higher rate;
    IF TelAllHighFlag&psn = 1 THEN DO ; * Assign higher rate to those who qualify 
                                          for it ;
    * Single rate ; * Convert from Quarterly to fortnightly amount ;
        IF Coupleu = 0 THEN TelAllF&psn = TelAllHighMaxAS / 26 ; 
   
        ELSE IF Coupleu = 1 THEN DO ; * Couple rate ;
          * If Partner does not receive a Pension, Allowance or CSHC then Telephone 
            Allowance is paid at the Couple Higher rate ;
            IF PenType&partner = ''   
            AND AllowType&partner = ''   
            AND CshcFlag&partner  = 0  

               THEN TelAllF&psn = TelAllHighMaxAC / 26 ; * Convert from Quarterly to 
                                                        fortnightly amount ;
         
          * IF Partner receives a Pension, Allowance or is eligible for the 
            Commonwealth Seniors Health Card. ;
            ELSE IF ( PenType&partner NOT IN ( '' )    
                   OR AllowType&partner NOT IN ( '' )  
                   OR CshcFlag&partner = 1 ) 
            THEN DO ;

              * Partner does not receive Telephone Allowance, Telephone Allowance is 
                paid at the Single Higher rate. ;
                IF TelAllHighFlag&partner = 0 
                AND TelAllLowFlag&partner = 0 

                    THEN TelAllF&psn = TelAllHighMaxAS / 26 ; * Convert from Quarterly to 
                                                            fortnightly amount ;
               
              * Partner receives Telephone Allowance at the lower rate, Telephone 
                Allowance is paid at the Single Higher rate. ;
                ELSE IF TelAllLowFlag&partner = 1 

                   THEN  TelAllF&psn = TelAllLowMaxAS / 26 ; * Convert from Quarterly to 
                                                           fortnightly amount ;
             
              * Partner receives Telephone Allowance at the higher rate, Telephone 
                Allowance is paid at the Couple Higher rate. ;
                ELSE IF TelAllHighFlag&partner = 1 

                   THEN  TelAllF&psn = TelAllHighMaxAC / 26 ; * Convert from Quarterly to 
                                                            fortnightly amount ;
           
            END ; * End partner receives a Pension, Allowance or CSHC ;

        END; * End of Couple ;

    END ; * End of higher rate ;

    * Assign rate of telephone allowance for those eligible for lower rate. ;
    ELSE IF TelAllLowFlag&psn = 1 THEN DO ; 
        * Single rate. Convert from Quarterly to fortnightly amount ;                         
        IF Coupleu = 0 THEN TelAllF&psn = TelAllLowMaxAs / 26 ; 
       
        ELSE IF Coupleu = 1 THEN DO ; * Couple rate ;
        * If Partner does not receive a Pension, Allowance or CSHC then Telephone 
          Allowance is paid at the Couple Lower rate ;
            IF PenType&partner = '' AND  
               AllowType&partner = '' AND  
               CshcFlag&partner  = 0  

               THEN TelAllF&psn = TelAllLowMaxAc / 26 ; * Convert from Quarterly to 
                                                       fortnightly amount ;
            * IF Partner receives a Pension, Allowance or is eligible for the 
            Commonwealth Seniors Health Card. ;
            ELSE IF ( PenType&partner NOT IN ( '' )   OR 
                      AllowType&partner NOT IN ( '' ) OR 
                      CshcFlag&partner = 1 ) THEN DO ;

              * Partner does not receive Telephone Allowance, Telephone Allowance is 
                paid at the Single Lower rate. ;
                IF TelAllHighFlag&partner = 0 AND TelAllLowFlag&partner = 0 

                   THEN TelAllF&psn = TelAllLowMaxAs / 26 ; * Convert from Quarterly to 
                                                           fortnightly amount ;
         
              * Partner receives Telephone Allowance at the lower rate, Telephone 
                Allowance is paid at the Couple lower rate. ;
                ELSE IF TelAllLowFlag&partner = 1  

                    THEN TelAllF&psn = TelAllLowMaxAc / 26 ; * Convert from Quarterly to 
                                                           fortnightly amount ;
              END ; * End partner receives a Pension, Allowance or CSHC ;

        END; * End of Couple ;

    END ; * End of lower rate ;

    TelAllA&psn = TelAllF&psn * 26 ;

%MEND TelephoneAllRate ;

**********************************************************************************
*   Macro:   UtilitiesAll                                                        *
*   Purpose: Determine eligibility for and assign rate of Utilities Allowance.   *
*********************************************************************************;;

%MACRO UtilitiesAll( psn ) ;

    * Eligibility ;
    IF PenType&psn = 'DSPU21'                                           /* Receives DSP at the under 21 rate */
    OR ( AllowType&psn IN ( 'PARTNER' , 'WIDOW' )                       /* receives Partner or Widow  */
         AND ( ( Sex&psn = 'F' AND ActualAge&psn < FemaleAgePenAge )    /* Allowance and is */       
            OR ( Sex&psn = 'M' AND ActualAge&psn < MaleAgePenAge ) ) )  /* under Age Pen age */ 

        THEN UtilitiesAllFlag&psn = 1 ;

    * Rate ; 
    IF UtilitiesAllFlag&psn = 1 THEN DO ;

        IF Coupleu = 0 THEN UtilitiesAllF&psn = UtilitiesAllMaxAS / 26 ; 

        ELSE IF Coupleu = 1 THEN UtilitiesAllF&psn = UtilitiesAllMaxAC / 26 ; 

        UtilitiesAllA&psn = UtilitiesAllF&psn * 26 ;

    END ;

%MEND UtilitiesAll ;

**********************************************************************************
*   Macro:   SinIncFamSup                                                        *
*   Purpose: Determine eligibility for and assign rate of Single Income Family   *
*            Supplement.                                                         *
*********************************************************************************;;
%MACRO SinIncFamSup( psn , partner ) ;

*2016-17 Budget - SIFS closed on 1 July 2017 - CAPITA does not model the grandfathering of the removal; 
 %IF ( &Duration = A AND &Year < 2017 ) 
	 OR ( &Duration = Q AND &Year < 2017 ) 
	 OR ( &Duration = Q AND &Year = 2017 AND ( &Quarter = Mar or  &Quarter = Jun ) )
 %THEN %DO ; 
*End; 

  * Eligibility ;
  * Note that an equal earner couple could never qualify for SIFS as the allowable
    income ranges for the primary and secondary earners will never overlap. ;
    IF DepsSifs    > 0                           /* At least one SIFS Dependent Child */                                     
    AND TaxIncA&psn > TaxIncA&partner            /* Be the primary income earner in the family*/
    AND SifsThrLwr <= TaxIncA&psn <= SifsthrUpr  /* Be between the income thresholds */
    THEN DO ;

        SifsFlag = 1 ;
        SifsPrimFlag&psn = 1 ;

    END ;

  * Apply primary earner income test ;
    IF SifsFlag = 1 THEN DO ;

      * If taxable income is between The SIFS lower threshold and the SIFS middle 
        threshold which is the point where the reduction taper starts to kick in, 
        the payment increases by 2.5c for every dollar of income above the SIFS  
        lower threshold until the SIFS payment rate reaches its maximum;
        IF SifsThrLwr <= TaxIncA&psn <= SifsThrMid 

            THEN SifsA = MIN( SifsMaxA , ( TaxIncA&psn - SifsThrLwr ) * SifsTpr1 ) ;

      * If taxable income is between The SIFS middle threshold and the SIFS upper 
        threshold the rate of SIFS is reduced by 1c for every dollar above the  
        middle threshold until it reaches zero.;
        ELSE IF SifsThrMid < TaxIncA&psn

            THEN SifsA = MAX( 0 , SifsMaxA - ( ( TaxIncA&psn - SifsThrMid ) * SifsTpr2 ) ) ;


      * Apply the secondary earner income test ;
        IF TaxIncA&partner > SifsPartThr 

            THEN SifsA = MAX( 0 , 
                    SifsA - ( ( TaxIncA&partner - SifsPartThr ) * SifsPartTpr ) ) ;

      * Assign amount to secondary income earner (if one exists) ;
        IF SifsPrimFlag&psn = 1 
        AND Coupleu = 1 
        THEN SifsA&partner = SifsA ;

        ELSE SifsA&psn = SifsA ;
            
      * Convert from annual to fortnightly amount ; 
        SifsF&partner = SifsA&partner / 26 ;
        SifsF&psn = SifsA&psn / 26 ; 

    END ;

%END; 

%MEND SinIncFamSup ;

**********************************************************************************
*   Macro:   SupplementsAggregates                                               *
*   Purpose: Determine the aggregate amount of supplements that each individual  *
*            receives and the total amount for the whole population.             *
*********************************************************************************;;
%MACRO SupplementsAggregates( psn ) ;

    SupTotF&psn = CareAllF&psn      
                + CareSupF&psn      
                + IncSupBonF&psn    
                + SenSupF&psn 
                + SenSupEsF&psn 
                + PenEdSupF&psn     
                + TelAllF&psn       
                + UtilitiesAllF&psn 
                + SifsF&psn ;

    SupTotA&psn = SupTotF&psn * 26 ;

%MEND SupplementsAggregates ;

* Now call all the code ;

%RunSupplements
