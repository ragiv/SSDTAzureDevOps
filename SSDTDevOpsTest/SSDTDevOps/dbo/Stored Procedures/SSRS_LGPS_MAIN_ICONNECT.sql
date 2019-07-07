

-- =============================================
-- Author:		Colin Henderson
-- Create date: 8th April 2016
-- Description:	LGPS MAIN Version 1.2
--
-- Updated by:	Stephen Mountier
-- Create date: 7th January 2019
--
-- Updated by:	Stephen Mountier
-- Create date: 25th February 2019
-- Description of Update: To incorporate Date Joined LSPS where School joined later than the Appointment Date of Employee
--
-- Updated by:	Connull Dunbar
-- Create date:	28th March 2019
-- Description:	Issue with the "PartTime_Hours_EffectiveDate" - report selecting the last Appointment record even if the part
--              time hours hasn't changed
--              Example - Appointment No. - B978015, School - C002097, Tax Year - 2019, Period - 11 
-- Version:		1.3.280319.160959
--
-- Updated by:	Connull Dunbar
-- Create date:	08th May 2019
-- Description:	Issue with comparing decimals in subquery ... fixed by rounding both comparables to 2 dcps
-- Version:		v1.4.080519.132707
--
-- Updated by:	Connull Dunbar
-- Create date:	08th May 2019
-- Description: Two subsequent changes
--              1) If "PartTime_Hours_Effective_Date" is before the "EPM Payroll Effectivefrom Date" on the Customer record,
--                 set it to the "EPM Payroll Effectivefrom Date"
--              2) Changed one of the fields used in the comparison (Version - 1.3.280319.160959) - "Full Time Hours" to "Total Hours"
-- Version:		v1.5.080519.144910
-- =============================================


CREATE PROCEDURE [dbo].[SSRS_LGPS_MAIN_ICONNECT] (@Pensions Varchar(4)
                                       ,@TAXYEAR int
                                       ,@PERIOD int
                                       ,@DfES Varchar(10)
									   ,@School Varchar(10)
									   ,@PensionCode Varchar(10)
									   ,@All Varchar(1)
									   ,@NewStarters varchar(1)
									   ,@Leavers varchar(1)
									   ,@changes varchar(1)
									   ,@Customertype varchar(100)
									   ,@OriginalAppointment Varchar(10)
									   )

AS

/* START of Added Code MSS 
   This allows for a Period of 0 to be sent across from the Report 
   that indicates the the Report is to be run in Fiscal Yearly mode */
	DECLARE @PERIOD1 int	
	DECLARE @PERIOD2 int
	IF @PERIOD = 0
		BEGIN
			SET @PERIOD1 = 1
			SET @PERIOD2 = 12
		END
	ELSE
		BEGIN
			SET @PERIOD1 = @PERIOD
			SET @PERIOD2 = @PERIOD
		END
/* END of Added Code by MSS */

	DECLARE  @PeriodStart Date = cast((Select  distinct FirstDayOfMonth   from DimDate_SSRS dm where TaxYear = @TAXYEAR and TaxPeriod = @PERIOD1 ) as date)
	DECLARE  @PeriodEnd Date =  cast((Select  distinct LastDayOfMonth  from DimDate_SSRS dm where TaxYear = @TAXYEAR and TaxPeriod = @PERIOD2 ) as date)
	DECLARE  @PeriodEnd_1 Date = cast((Select distinct DATEADD(DD,-1,LastDayOfMonth) from DimDate_SSRS dm where TaxYear = @TAXYEAR and TaxPeriod = @PERIOD2 ) as date)
	DECLARE  @PreviousTaxPeriod int = cast((Select dm.TaxPeriod from DimDate_SSRS dm where DimDate = DATEADD(DAY,-1,@PeriodStart)) as int)
	DECLARE  @PreviousTaxYear int   =  cast((Select dm.TaxPeriod  from DimDate_SSRS dm where DimDate = DATEADD(DAY,-1,@PeriodStart))  as int)
    

	DECLARE  @PEN8PeriodStart Date
	DECLARE  @PEN8PeriodStart13 Date
	DECLARE  @PEN8PeriodEnd13 Date

	  SET @PEN8PeriodStart = DATEADD(DD,1,DATEADD(MM,-12,@PeriodEnd))
/* MSS Added below For 13th month issue of regignations mid-month - Needing to calculate the Pen8FTE Amount! */
	  SET @PEN8PeriodStart13 = DATEADD(DD,1,DATEADD(MM,-13,@PeriodEnd))
	  SET @PEN8PeriodEnd13 = DATEADD(DD,1,DATEADD(DD,-2,@PEN8PeriodStart))

	DECLARE  @Pen8_365Days decimal = (select count(dm.dimdate) from DimDate_SSRS dm where dm.dimdate between @PEN8PeriodStart and @PeriodEnd)
	
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	BEGIN


		--set @School = isnull(@School,'')
		--set @DfES   = isnull(@dfes,'') 
		--set @PensionCode = isnull(@PensionCode,'')
	
		set @Customertype = isnull(@CustomerType,'')

	--	IF OBJECT_ID('tempdb..#LGPSDATA') IS NOT NULL DROP TABLE #LGPSDATA
		IF OBJECT_ID('tempdb..#LGPSMonthlySummary') IS NOT NULL DROP TABLE #LGPSMonthlySummary
		IF OBJECT_ID('tempdb..#OutputLGPS') IS NOT NULL DROP TABLE #OutputLGPS
		IF OBJECT_ID('dbo.SSRS_OutputLGPS') IS NOT NULL DROP TABLE SSRS_OutputLGPS
		IF OBJECT_ID('tempdb..#PensionType') IS NOT NULL DROP TABLE #PensionType
		IF OBJECT_ID('tempdb..#LGPSYTD') IS NOT NULL DROP TABLE #LGPSYTD
--		IF OBJECT_ID('tempdb..#LGPSYTD') IS NOT NULL DROP TABLE #LGPSYTD
		IF OBJECT_ID('tempdb..#LGPSPayrollEmployee') IS NOT NULL DROP TABLE #LGPSPayrollEmployee
		IF OBJECT_ID('tempdb..#Customer') IS NOT NULL DROP TABLE #Customer
		IF OBJECT_ID('tempdb..#PEN8_DATA_LOCAL') IS NOT NULL DROP TABLE #PEN8_DATA_LOCAL
		IF OBJECT_ID('tempdb..#HREmp') IS NOT NULL DROP TABLE #HREmp
--        IF OBJECT_ID('dbo.SSRS_Periods') IS NOT NULL DROP TABLE SSRS_Periods
--        IF OBJECT_ID('dbo.SSRS_Period13') IS NOT NULL DROP TABLE SSRS_Period13
        IF OBJECT_ID('tempdb..#Periods') IS NOT NULL DROP TABLE #Periods
        IF OBJECT_ID('tempdb..#Period13') IS NOT NULL DROP TABLE #Period13
        IF OBJECT_ID('tempdb..#Pen8AppointmentInfo') IS NOT NULL DROP TABLE #Pen8AppointmentInfo
        IF OBJECT_ID('tempdb..#OriginalAppointmentInfo') IS NOT NULL DROP TABLE #OriginalAppointmentInfo
        IF OBJECT_ID('tempdb..#HistoricalAppointmentInfo') IS NOT NULL DROP TABLE #HistoricalAppointmentInfo
 --       IF OBJECT_ID('tempdb..#HistoricalAppointmentInfo') IS NOT NULL DROP TABLE #HistoricalAppointmentInfo
        IF OBJECT_ID('tempdb..#HoursEffectiveFrom') IS NOT NULL DROP TABLE #HoursEffectiveFrom

		-------------------------------------------------------------------------------------------------------
		--v1.3.280319.160959
		IF OBJECT_ID('tempdb..#LastAppointmentRec') IS NOT NULL DROP TABLE #LastAppointmentRec
		--v1.3.280319.160959
		-------------------------------------------------------------------------------------------------------

/* MSS:  PensionType Temporary Table does not seem ever to be used! */

		SELECT DISTINCT pen.[pension type]   
		  into #PensionType
		  FROM  [EPM$Pension Scheme]   PEN 
		  WHERE ( @Pensions = 'LGPS' and  pen.[pension type]   in (3,4) or @Pensions = 'TPS' and pen.[pension type]   in (3,4))

/* MSS:  PensionType Temporary Table does not seem ever to be used! */
		 
       Select distinct CASE WHEN @PEN8PeriodStart BETWEEN dm.FirstDayOfMonth and dm.LastDayOfMonth then @PEN8PeriodStart else dm.FirstDayOfMonth END as 'AppointmentFirstDayOfMonth'
                      ,case WHEN @PeriodEnd        BETWEEN dm.FirstDayOfMonth and dm.LastDayOfMonth then @PeriodEnd       else dm.LastDayOfMonth  END as 'AppointmentLastDayOfMonth'
					  ,dm.LastDayOfMonth  as 'LastDayOfMonth'
			          ,dm.TaxPeriod
			          ,dm.TaxYear
			          ,cast(count(dm.dimdate) as decimal(10,6)) as 'DaysInPeriod'
			          ,cast((Select count(dm2.MonthYear) from DimDate_SSRS dm2  where dm2.MonthYear= dm.MonthYear) as decimal(10,6)) AS 'DaysInMonth'
                into #Periods
                from DimDate_SSRS dm
               where dm.DimDate between @PEN8PeriodStart and @PeriodEnd
               group by dm.FirstDayOfMonth,dm.LastDayOfMonth,dm.TaxPeriod,dm.TaxYear,dm.MonthYear

       Select distinct CASE WHEN @PEN8PeriodStart BETWEEN dm.FirstDayOfMonth and dm.LastDayOfMonth then @PEN8PeriodStart else dm.FirstDayOfMonth END as 'AppointmentFirstDayOfMonth'
                      ,case WHEN @PeriodEnd        BETWEEN dm.FirstDayOfMonth and dm.LastDayOfMonth then @PeriodEnd       else dm.LastDayOfMonth  END as 'AppointmentLastDayOfMonth'
					  ,dm.LastDayOfMonth  as 'LastDayOfMonth'
			          ,dm.TaxPeriod
			          ,dm.TaxYear
			          ,cast(count(dm.dimdate) as decimal(10,6)) as 'DaysInPeriod'
			          ,cast((Select count(dm2.MonthYear) from DimDate_SSRS dm2  where dm2.MonthYear= dm.MonthYear) as decimal(10,6)) AS 'DaysInMonth'
                into #Period13
                from DimDate_SSRS dm
               where dm.DimDate between @PEN8PeriodStart13 and @PEN8PeriodEnd13
               group by dm.FirstDayOfMonth,dm.LastDayOfMonth,dm.TaxPeriod,dm.TaxYear,dm.MonthYear


--
-- GET ALL The Pension Payment Totals in the current Period
-- Against Original Appointment Number.
--	

	 Select *  into #Customer 
	 from [EPM$Customer] cs
	 WHERE cs.[DfES Area] = ISNULL(@DfES,cs.[DfES Area])
	  and cs.No_ = isnull(@School,cs.No_ ) 
	  and (cs.[Employer Pension Code] = ISNULL(@PensionCode,cs.[Employer Pension Code])  or cs.[LGPS Pension Fund] = isnull(@PensionCode,cs.[LGPS Pension Fund] ) )
	  and cs.[Payroll Provider] = 'EPM'
	  and ( cs.[EPM Payroll End Date] = '1753-01-01' or cs.[EPM Payroll End Date]  >  @PeriodStart)

Print('Placeholder -3')
-- Temporary table grouping HR Employee Information

SELECT   
Title
,[First Name]
,[Last Name]
,Sex  
,[No_]
,[School No_]
,[Birth Date]  
,[Address]
,[Address 2]
,[Post Code]
,City
,County
,[DFES No_]
INTO #HREmp
FROM 
[EPM$School Employee]
WHERE
[School No_] in (SELECT [No_] FROM #Customer)
GROUP BY 
Title
,[First Name]
,[Last Name]
,Sex  
,[No_]
,[School No_]
,[Birth Date]  
,[Address]
,[Address 2]
,[Post Code]
,City
,County
,[DFES No_]

-- Main query
Print('Placeholder -2')
select * INTO #LGPSMonthlySummary FROM (
  Select @TAXYEAR                       as 'ReportTaxYear'
        ,@PERIOD                        as 'ReportPeriod'
        ,@PeriodStart                   as 'ReportPayPeriodStart'
		, Concat( cast(@TaxYear -1 as varchar(4)),   '/',Right(cast(@TaxYear as varchar(4)),2))                               as 'ReportExtendedTaxYear'
        ,@PeriodEnd                     as 'ReportPayPeriodEnd'  
        ,PDL.Period                     as 'PayDetailLinePeriod'
        ,PDL.[Tax Year]                 as 'PayDetailLineTaxYear'
		,DateName(month,DateAdd(MM,2+PDL.Period,DateAdd(d, -DatePart(dy,getdate()-1),getdate()))) as 'PayDetailMonth'
        ,pdl.[Payroll Group Code]       as 'PayDetailPayrollGroupCode'
        ,cast(pdl.[Payroll Date] as date) as 'PayDetailPayrollDate'
        ,pdl.[Original Appointment No_] as 'PayDetailOriginalAppointmentNumber'
        ,pdl.[Pension 1]                as 'PayDetailPension1'
		,pdl.[Employee No_]             as 'PayDetailEmployeeNumber'  

		-- Customer Information
		,CUS.[DfES Area]
        ,CUS.[Employer Pension Code] As 'CustomerEmployerPensionCode'
        ,cus.[School DfES No_]       as 'CustomerSchoolDfESAlpha'
        ,replace(cus.[School DfES No_],'/','') as 'CustomerSchoolDfESNumber'
        ,cus.[PAYROLL REF]                     as 'CustomerPayrollRef'
        ,cast(CUS.Name   as varchar(40) )      as 'CustomerName'
        ,CUS.[Customer Type]                   as 'CustomerType'
        ,CUS.[Employer Code]                   as 'CustomerEmployerCode'

-- Payroll Employee Information
		 ,cast(PEM.[Join Date] as date)								  as 'PayrollEmployeeJoinDate'
         ,cast(PEM.Forenames  as varchar(25))                          as 'PayrollEmployeeFornames'
         ,Cast(PEM.Surname  as varchar(25))                           as 'PayrollEmployeeSurname'
         ,PEM.Title                                                   as 'PayrollEmployeeTitle'
		 ,CASE WHEN PEM.TITLE LIKE 'M%' THEN PEM.TITLE ELSE ''END     as 'LGSSEmployeeTitle'
         ,PEM.[No_]                                                   as 'PayRollEmployeeNumber'
         ,CASE PEM.Sex WHEN 1 THEN 'F' ELSE 'M' END					  as 'PayrollEmployeeSex' 
         ,PEM.[NI Number]                                             as 'PayrollEmployeeNINumber'
        , replace(CASE ISNUMERIC(replace(pem.[Address],' ',''))
            WHEN 1 THEN REPLACE(CONCAT(pem.[Address],' ',pem.[Address 2]),',',' ')
              ELSE pem.[Address]
              END,',',' ') as 'PayrollEMployeeAddress1' 

        ,replace(CASE ISNUMERIC(replace(pem.[Address],' ',''))
             WHEN 1 THEN ''
                   ELSE pem.[Address 2]
                 END ,',',' ')as 'PayrollEmployeeAddress2'
  
        ,replace(PEM.[Post code]  ,',','')                                             as 'PayrollEMployeePostCode'                                




-- HR Employee Information
         ,emp.Title as 'EmployeeTitle'
         ,emp.[First Name] as 'EmployeeFirstName'
         ,emp.[Last Name] as 'EmployeeLastName'
         ,CASE emp.Sex  WHEN 1 THEN 'F' ELSE 'M' END as 'EmployeeGender'
         ,emp.[No_] as 'EmployeeNumber'
         ,cast(emp.[Birth Date] as date) as 'EmployeeDOB'   
         ,CASE ISNUMERIC(replace(emp.[Address],' ',''))
               WHEN 1 THEN REPLACE(CONCAT(emp.[Address],' ',emp.[Address 2]),',',' ')
               ELSE emp.[Address] END as 'EmployeeAddress'  
         ,CASE ISNUMERIC(replace(emp.[Address],' ',''))
              WHEN 1 THEN '' ELSE emp.[Address 2] END as 'EmployeeAddress2'
        ,replace(emp.[Post Code],',',' ') as 'EmployeePostcode'
        ,replace(emp.City,',',' ')       As 'EmployeeCity'
        ,replace(emp.County,',',' ')     as 'EmployeeCounty'
		,Replace(emp.[DFES No_],'/','')  as   'EmployeeTeacherDFENumber'


-- Totals


/*[Pension Type]
1 = Teacher TPS
2 = Teacher AVC
3 = LG
4 = LG AVC

[Type]
 0 = Percentage
 1 = Fixed
 2 = AVC Percentage
 3 = AVC Fixed
 4 = Comp
 5 = Stakeholder

 */


		,max(CASE WHEN pen.[pension type] in (1,3) and pen.[type] = 0 THEN [Ee Pens_ Contr_ %] ELSE 0 END ) as 'EmployeePensionPercentage'

		,cast(sum(CASE WHEN pen.[Pension Type] in (1,3) 
              and pen.[50_50 Scheme] = 0 
			  and pen.[Added Years]  = 0
			 THEN pdl.amount 
			 ELSE 0 
			 END ) as decimal(10,2)) as 'PeriodEmployeeAmount'

        ,cast(sum(CASE WHEN pen.[Pension Type] in (1,3) 
              and pen.[50_50 Scheme] = 1 
			  and pen.[Added Years]  = 0 
			  THEN pdl.amount 
			  ELSE 0 
			  END ) as decimal(10,2)) as 'Period50-50EmployeeAmount'

        ,cast(sum(CASE WHEN pen.[Pension Type] in (2,4)
              and pen.[50_50 Scheme] = 0 
			  and pen.[Added Years]  = 1 
			  THEN pdl.amount 
			  ELSE 0 
			  END ) as decimal(10,2))  as 'PeriodEmployeeAddedYearsAmount'

        ,cast(sum(CASE WHEN pen.[Pension Type] in (4) --and pen.[type] in (2,3) --AVC
			  and pen.[Added Years]  = 0 
			  and pdl.[Reference] like '%APC%'
			  THEN pdl.amount 
			  ELSE 0 
			  END ) as decimal(10,2)) as 'PeriodEmployeeAPCAmount'

        ,cast(sum(CASE WHEN pen.[Pension Type] in (2,4)  --and pen.[type] in (2,3) --AVC
			  and pen.[Added Years]  = 0 
			  and  (pdl.[Reference] not like '%APC%')
			  THEN pdl.amount 
			  ELSE 0 
			  END )  as decimal(10,2)) as 'PeriodEmployeeAVCAmount'

	   ,cast(sum(pdl.amount) as decimal(10,2))as 'PeriodEmployeeTotalPensionAmount'


-- Employers Amounts (doesnt matter if it is 50-50 or main)
	,cast(sum(CASE WHEN pen.[Pension Type] in (1,3) 
      --        and pen.[50_50 Scheme] = 0 
			  and pen.[Added Years]  = 0
			 THEN pdl.[Employer Amount]
			 ELSE 0 
			 END ) as decimal(10,2)) as 'PeriodEmployerAmount'

        ,cast(sum(CASE WHEN pen.[Pension Type] in (1,3) 
              and pen.[50_50 Scheme] = 1 
			  and pen.[Added Years]  = 0 
			  THEN  0  --pdl.[Employer Amount]
			  ELSE 0 
			  END )  as decimal(10,2)) as 'Period50-50EmployerAmount'

        ,cast(sum(CASE WHEN pen.[Pension Type] in (2,4) 
              and pen.[50_50 Scheme] = 0 
			  and pen.[Added Years]  = 1 
			  THEN pdl.[Employer Amount] 
			  ELSE 0 
			  END ) as decimal(10,2)) as 'PeriodEmployerAddedYearsAmount'   


        ,cast(sum(CASE WHEN pen.[Pension Type] not in (2,4) --and pen.[type] in (2,3)
			  and pen.[Added Years]  = 0 
			  and pdl.[Reference] like '%APC%'
			  THEN pdl.[Employer Amount] 
			  ELSE 0 
			  END ) as decimal(10,2)) as 'PeriodEmployerAPCAmount'

        ,cast(sum(CASE WHEN pen.[Pension Type] in (2,4)  --and pen.[type] in (2,3) --AVC
              and pen.[50_50 Scheme] = 0 
			  and pen.[Added Years]  = 0 
			  and  (pdl.[Reference] not like '%APC%')
			  THEN pdl.[Employer Amount] 
			  ELSE 0 
			  END ) as Decimal(10,2)) as 'PeriodEmployerAVCAmount'
	   
	    ,cast(sum(pdl.[Employer Amount]) as decimal(10,2)) as 'PeriodEmployerTotalPensionAmount'
			        
		,cast(sum(CASE WHEN ISNULL(pdl.Description, '') like 'LGPS Office%'
			 THEN pdl.[Pensionable Pay] ELSE 0 END)  as decimal(10,2))As 'PeriodPensionablePay'

	    ,cast(sum(CASE WHEN pen.[Pension Type] in (1,3) 
              and pen.[50_50 Scheme] = 0 
			  and pen.[Added Years]  = 0
			  --and pdl.Description <> 'LGPS Office'
			 THEN pdl.[Pensionable Pay]
			 ELSE 0 
			 END )  as decimal(10,2)) as 'PeriodMainPensionablePay'

        ,cast(sum(CASE WHEN pen.[Pension Type] in (1,3) 
              and pen.[50_50 Scheme] = 1 
			  and pen.[Added Years]  = 0 
			  THEN pdl.[Pensionable Pay]
			  ELSE 0 
			  END ) as decimal(10,2)) as 'Period5050PensionablePay'


        , cast(000.00 as decimal(16,2))  as 'MainCumlativePensionablePayYTD',
          cast(000.00 as Decimal(16,2))  as 'MainEmployeeContributionsYTD',
		  cast(000.00 as Decimal(16,2))  as 'MainEmployerContributionsYTD',
          cast(000.00 as decimal(16,2))  as '5050PensionablePayYTD',
          cast(000.00 as decimal(16,2))  as '5050EmployerContributionYTD',
          cast(000.00 as decimal(16,2))  as '5050EmployeeContributionYTD',
		  cast(000.00 as decimal(16,2))  as 'EmployeeAddedYearsYTD',
		  cast(000.00 as decimal(16,2))  as 'EmployerAddedYearsYTD',
		  cast(000.00 as decimal(16,2))  as 'EmployeeAVCYTD',
		  cast(000.00 as decimal(16,2))  as 'EmployerAVCYTD',
		  cast(000.00 as decimal(16,2))  as 'EmployeeAPCYTD',
		  cast(000.00 as decimal(16,2))  as 'EmployerAPCYTD',
		  cast(000.00 as decimal(16,2))  as 'EmployeeFIXYTD',
		  cast(000.00 as decimal(16,2))  as 'EmployerFIXYTD',
          cast(000.00 as decimal(16,2))  as 'Assumed Pensionable Pay',
		  cast(000.00 as decimal(16,2))  as 'AnnualPensionableSalary',
		  cast(000.00 as Decimal(16,2))  as 'Pen8FTEAmount',
		  cast(000.00 as Decimal(16,2))  as 'Pen8WeeksWorkedAmount',
		  cast(000.00 as Decimal(16,2))  as 'AnnualisedPen8FTEAmount',
		  cast(000.00 as Decimal(16,2))  as 'EmployerTotalPensionAmountYTD',
		  'Y'                            as 'PeriodEmployeePensionTotalsOK',
		  'Y'                            as 'PeriodEmployerPensionTotalsOK',
		  'Y'                            as 'YTDEmployeePensionTotalsOK',
		  'Y'                            as 'YTDEmployerPensionTotalsOK'

    From  #Customer cs
	      INNER JOIN [EPM$Customer] cus ON cs.no_ = cus.No_
		  INNER JOIN [EPM$Pay Detail Line] Pdl ON pdl.[Payroll Group Code] = cus.No_
	      INNER JOIN [EPM$Pension Scheme]   PEN  ON PDL.[Reference] = PEN.[Scheme No_]and   (pen.[Pension Type] in (1,2) and @Pensions = 'TPS' or  pen.[Pension Type] in (3,4) and @Pensions = 'LGPS')
		  INNER JOIN [EPM$Payroll Employee] pem on PDL.[Employee No_] = pem.No_ and pdl.[Payroll Group Code] = pem.[Payroll Group Code]
		  INNER JOIN #HREmp emp on pem.[HR Employee No_] = emp.No_ and cus.No_ = emp.[School No_]
	where cs.no_ = cus.No_
	  and pdl.[Payroll Group Code] = cus.No_ 
	  and pdl.[Pay Element Code] = 'PENSION'
--	  and pdl.[Employee No_] not like '%R%'
	  and ( pdl.[Tax Year] = @TAXYEAR and ((pdl.Period = @PERIOD) OR @PERIOD=0))
	  and pdl.Amount <> 0 and cus.no_ = emp.[School No_]
	  Group by PDL.Period 
              ,PDL.[Tax Year] 
	          ,pdl.[Payroll Group Code]
              ,pdl.[Payroll Date]
              ,pdl.[Original Appointment No_]
			  ,pdl.[Employee No_]
              ,pdl.[Pension 1]	  
	  		  ,CUS.[DfES Area]
              ,CUS.[Employer Pension Code]
              ,cus.[School DfES No_]
              ,cus.[PAYROLL REF]
              ,CUS.Name
              ,CUS.[Customer Type]
              ,CUS.[Employer Code]
              ,CUS.[Employer Pension Code]
-- Payroll Employee Information
	          ,PEM.[Join Date] 
              ,PEM.Forenames
              ,PEM.Surname 
              ,PEM.Title 
              ,PEM.[No_]
              ,CASE PEM.Sex WHEN 1 THEN 'F' ELSE 'M' END
              ,PEM.[NI Number]   
              ,CASE ISNUMERIC(replace(pem.[Address],' ',''))WHEN 1 THEN REPLACE(CONCAT(pem.[Address],' ',pem.[Address 2]),',',' ')
                ELSE pem.[Address] END 
              ,CASE ISNUMERIC(replace(pem.[Address],' ','')) WHEN 1 THEN ''
                   ELSE pem.[Address 2]END   
              ,PEM.[Post code]   
-- HR Employee Information 			  		  
              ,emp.Title
              ,emp.[First Name] 
              ,emp.[Last Name] 
              ,CASE emp.Sex  WHEN 1 THEN 'F' ELSE 'M' END
              ,emp.[No_]
              ,cast(emp.[Birth Date] as date) 
              ,CASE ISNUMERIC(replace(emp.[Address],' ',''))
               WHEN 1 THEN REPLACE(CONCAT(emp.[Address],' ',emp.[Address 2]),',',' ')
               ELSE emp.[Address] END  
              ,CASE ISNUMERIC(replace(emp.[Address],' ',''))
              WHEN 1 THEN '' ELSE emp.[Address 2] END 
              ,emp.[Post Code]
             ,emp.City 
             ,emp.County 
		     ,Replace(emp.[DFES No_],'/','') 		                              

   UNION

     Select @TAXYEAR                    as 'ReportTaxYear'
        ,@PERIOD                        as 'ReportPeriod'
        ,@PeriodStart                   as 'ReportPayPeriodStart'
		, Concat( cast(@TaxYear -1 as varchar(4)),   '/',Right(cast(@TaxYear as varchar(4)),2))                               as 'ReportExtendedTaxYear'
        ,@PeriodEnd                     as 'ReportPayPeriodEnd'  
        ,PDL.Period                     as 'PayDetailLinePeriod'
        ,PDL.[Tax Year]                 as 'PayDetailLineTaxYear'
		,DateName(month,DateAdd(MM,2+PDL.Period,DateAdd(d, -DatePart(dy,getdate()-1),getdate()))) as 'PayDetailMonth'
        ,pdl.[Payroll Group Code]       as 'PayDetailPayrollGroupCode'
        ,cast(pdl.[Payroll Date] as date) as 'PayDetailPayrollDate'
        ,pdl.[Original Appointment No_] as 'PayDetailOriginalAppointmentNumber'
        ,pdl.[Pension 1]                as 'PayDetailPension1'
		,pdl.[Employee No_]             as 'PayDetailEmployeeNumber'  

		-- Customer Information
		,CUS.[DfES Area]
        ,CUS.[Employer Pension Code] As 'CustomerEmployerPensionCode'
        ,cus.[School DfES No_]       as 'CustomerSchoolDfESAlpha'
        ,replace(cus.[School DfES No_],'/','') as 'CustomerSchoolDfESNumber'
        ,cus.[PAYROLL REF]                     as 'CustomerPayrollRef'
        ,cast(CUS.Name   as varchar(40) )      as 'CustomerName'
        ,CUS.[Customer Type]                   as 'CustomerType'
        ,CUS.[Employer Code]                   as 'CustomerEmployerCode'

-- Payroll Employee Information
		 ,cast(PEM.[Join Date] as date)								  as 'PayrollEmployeeJoinDate'
         ,cast(PEM.Forenames  as varchar(25))                          as 'PayrollEmployeeFornames'
         ,Cast(PEM.Surname  as varchar(25))                           as 'PayrollEmployeeSurname'
         ,PEM.Title                                                   as 'PayrollEmployeeTitle'
		 ,CASE WHEN PEM.TITLE LIKE 'M%' THEN PEM.TITLE ELSE ''END     as 'LGSSEmployeeTitle'
         ,PEM.[No_]                                                   as 'PayRollEmployeeNumber'
         ,CASE PEM.Sex WHEN 1 THEN 'F' ELSE 'M' END					  as 'PayrollEmployeeSex' 
         ,PEM.[NI Number]                                             as 'PayrollEmployeeNINumber'
        , replace(CASE ISNUMERIC(replace(pem.[Address],' ',''))
            WHEN 1 THEN REPLACE(CONCAT(pem.[Address],' ',pem.[Address 2]),',',' ')
              ELSE pem.[Address]
              END,',',' ') as 'PayrollEMployeeAddress1' 

        ,replace(CASE ISNUMERIC(replace(pem.[Address],' ',''))
             WHEN 1 THEN ''
                   ELSE pem.[Address 2]
                 END ,',',' ')as 'PayrollEmployeeAddress2'
  
        ,replace(PEM.[Post code]  ,',','')                                             as 'PayrollEMployeePostCode'                                




-- HR Employee Information
         ,emp.Title as 'EmployeeTitle'
         ,emp.[First Name] as 'EmployeeFirstName'
         ,emp.[Last Name] as 'EmployeeLastName'
         ,CASE emp.Sex  WHEN 1 THEN 'F' ELSE 'M' END as 'EmployeeGender'
         ,emp.[No_] as 'EmployeeNumber'
         ,cast(emp.[Birth Date] as date) as 'EmployeeDOB'   
         ,CASE ISNUMERIC(replace(emp.[Address],' ',''))
               WHEN 1 THEN REPLACE(CONCAT(emp.[Address],' ',emp.[Address 2]),',',' ')
               ELSE emp.[Address] END as 'EmployeeAddress'  
         ,CASE ISNUMERIC(replace(emp.[Address],' ',''))
              WHEN 1 THEN '' ELSE emp.[Address 2] END as 'EmployeeAddress2'
        ,replace(emp.[Post Code],',',' ') as 'EmployeePostcode'
        ,replace(emp.City,',',' ')       As 'EmployeeCity'
        ,replace(emp.County,',',' ')     as 'EmployeeCounty'
		,Replace(emp.[DFES No_],'/','')  as   'EmployeeTeacherDFENumber'


-- Totals


/*[Pension Type]
1 = Teacher TPS
2 = Teacher AVC
3 = LG
4 = LG AVC

[Type]
 0 = Percentage
 1 = Fixed
 2 = AVC Percentage
 3 = AVC Fixed
 4 = Comp
 5 = Stakeholder

 */



		,max(CASE WHEN pen.[pension type] in (1,3) and pen.[type] = 0 THEN [Ee Pens_ Contr_ %] ELSE 0 END ) as 'EmployeePensionPercentage'

		,cast(sum(CASE WHEN pen.[Pension Type] in (1,3) 
              and pen.[50_50 Scheme] = 0 
			  and pen.[Added Years]  = 0
			 THEN pdl.amount 
			 ELSE 0 
			 END )  as decimal(10,2)) as 'PeriodEmployeeAmount'

        ,cast(sum(CASE WHEN pen.[Pension Type] in (1,3) 
              and pen.[50_50 Scheme] = 1 
			  and pen.[Added Years]  = 0 
			  THEN pdl.amount 
			  ELSE 0 
			  END ) as decimal(10,2)) as 'Period50-50EmployeeAmount'

        ,cast(sum(CASE WHEN pen.[Pension Type] in (2,4)
              and pen.[50_50 Scheme] = 0 
			  and pen.[Added Years]  = 1 
			  THEN pdl.amount 
			  ELSE 0 
			  END ) as decimal(10,2)) as 'PeriodEmployeeAddedYearsAmount'



        ,cast(sum(CASE WHEN pen.[Pension Type] in (4) --and pen.[type] in (2,3) --AVC
			  and pen.[Added Years]  = 0 
			  and pdl.[Reference] like '%APC%'
			  THEN pdl.amount 
			  ELSE 0 
			  END ) as decimal(10,2)) as 'PeriodEmployeeAPCAmount'

        ,cast(sum(CASE WHEN pen.[Pension Type] in (2,4)  --and pen.[type] in (2,3) --AVC
			  and pen.[Added Years]  = 0 
			  and  (pdl.[Reference] not like '%APC%')
			  THEN pdl.amount 
			  ELSE 0 
			  END ) as decimal(10,2)) as 'PeriodEmployeeAVCAmount'

	   ,cast(sum(pdl.amount) as decimal(10,2)) as 'PeriodEmployeeTotalPensionAmount'


-- Employers Amounts
	,cast(sum(CASE WHEN pen.[Pension Type] in (1,3) 
              and pen.[50_50 Scheme] = 0 
			  and pen.[Added Years]  = 0
			 THEN pdl.[Employer Amount]
			 ELSE 0 
			 END ) as decimal(10,2)) as 'PeriodEmployerAmount'

        ,cast(sum(CASE WHEN pen.[Pension Type] in (1,3) 
              and pen.[50_50 Scheme] = 1 
			  and pen.[Added Years]  = 0 
			  THEN pdl.[Employer Amount]
			  ELSE 0 
			  END )as decimal(10,2)) as 'Period50-50EmployerAmount'

        ,cast(sum(CASE WHEN pen.[Pension Type] in (2,4) 
              and pen.[50_50 Scheme] = 0 
			  and pen.[Added Years]  = 1 
			  THEN pdl.[Employer Amount] 
			  ELSE 0 
			  END ) as decimal(10,2)) as 'PeriodEmployerAddedYearsAmount'   


        ,cast(sum(CASE WHEN pen.[Pension Type] not in (2,4) --and pen.[type] in (2,3)
			  and pen.[Added Years]  = 0 
			  and pdl.[Reference] like '%APC%'
			  THEN pdl.[Employer Amount] 
			  ELSE 0 
			  END )  as decimal(10,2))as 'PeriodEmployerAPCAmount'

        ,cast(sum(CASE WHEN pen.[Pension Type] in (2,4)  --and pen.[type] in (2,3) --AVC
              and pen.[50_50 Scheme] = 0 
			  and pen.[Added Years]  = 0 
			  and  (pdl.[Reference] not like '%APC%')
			  THEN pdl.[Employer Amount] 
			  ELSE 0 
			  END ) as decimal(10,2)) as 'PeriodEmployerAVCAmount'
	   
	    ,cast(sum(pdl.[Employer Amount]) as decimal(10,2)) as 'PeriodEmployerTotalPensionAmount'
			        
		,cast(sum(CASE WHEN ISNULL(pdl.Description, '') like 'LGPS Office%'
			 THEN pdl.[Pensionable Pay] ELSE 0 END)  as decimal(10,2))As 'PeriodPensionablePay'

	    ,cast(sum(CASE WHEN pen.[Pension Type] in (1,3) 
              and pen.[50_50 Scheme] = 0 
			  and pen.[Added Years]  = 0
			 -- and pdl.Description <> 'LGPS Office'
			 THEN pdl.[Pensionable Pay]
			 ELSE 0 
			 END )  as decimal(10,2)) as 'PeriodMainPensionablePay'

        ,cast(sum(CASE WHEN pen.[Pension Type] in (1,3) 
              and pen.[50_50 Scheme] = 1 
			  and pen.[Added Years]  = 0 
			  THEN pdl.[Pensionable Pay]
			  ELSE 0 
			  END )  as decimal(10,2)) as 'Period5050PensionablePay'


        , cast(000.00 as decimal(16,2))  as 'MainCumlativePensionablePayYTD',
          cast(000.00 as Decimal(16,2))  as 'MainEmployeeContributionsYTD',
		  cast(000.00 as Decimal(16,2))  as 'MainEmployerContributionsYTD',
          cast(000.00 as decimal(16,2))  as '5050PensionablePayYTD',
          cast(000.00 as decimal(16,2))  as '5050EmployerContributionYTD',
          cast(000.00 as decimal(16,2))  as '5050EmployeeContributionYTD',
		  cast(000.00 as decimal(16,2))  as 'EmployeeAddedYearsYTD',
		  cast(000.00 as decimal(16,2))  as 'EmployerAddedYearsYTD',
		  cast(000.00 as decimal(16,2))  as 'EmployeeAVCYTD',
		  cast(000.00 as decimal(16,2))  as 'EmployerAVCYTD',
		  cast(000.00 as decimal(16,2))  as 'EmployeeAPCYTD',
		  cast(000.00 as decimal(16,2))  as 'EmployerAPCYTD',
		  cast(000.00 as decimal(16,2))  as 'EmployeeFIXYTD',
		  cast(000.00 as decimal(16,2))  as 'EmployerFIXYTD',
          cast(000.00 as decimal(16,2))  as 'Assumed Pensionable Pay',
		  cast(000.00 as decimal(16,2))  as 'AnnualPensionableSalary',
		  cast(000.00 as Decimal(16,2))  as 'Pen8FTEAmount',
		  cast(000.00 as Decimal(16,2))  as 'Pen8WeeksWorkedAmount',
		  cast(000.00 as Decimal(16,2))  as 'AnnualisedPen8FTEAmount',
		  cast(000.00 as Decimal(16,2))  as 'EmployerTotalPensionAmountYTD',
		  'Y'                            as 'PeriodEmployeePensionTotalsOK',
		  'Y'                            as 'PeriodEmployerPensionTotalsOK',
		  'Y'                            as 'YTDEmployeePensionTotalsOK',
		  'Y'                            as 'YTDEmployerPensionTotalsOK'
    From  #Customer cs
	      INNER JOIN [EPM$Customer] cus ON cs.no_ = cus.No_
		  INNER JOIN [EPM$Pay Detail Line] Pdl ON pdl.[Payroll Group Code] = cus.No_
	      INNER JOIN [EPM$Pension Scheme]   PEN  ON PDL.[Reference] = PEN.[Scheme No_]and   (pen.[Pension Type] in (1,2) and @Pensions = 'TPS' or  pen.[Pension Type] in (3,4) and @Pensions = 'LGPS')
		  INNER JOIN [EPM$Payroll Archive] pem on PDL.[Employee No_] = pem.No_ and pdl.[Payroll Group Code] = pem.[Payroll Group Code]
		  INNER JOIN #HREmp emp on pem.No_ = emp.No_ and cus.No_ = emp.[School No_]
	where cs.no_ = cus.No_
	  and pdl.[Payroll Group Code] = cus.No_  and pdl.[Employee No_] = emp.No_
	  and pdl.[Pay Element Code] = 'PENSION'
--	  and pdl.[Employee No_] not like '%R%'
	  and (pdl.[Tax Year] = @TAXYEAR and ((pdl.Period = @PERIOD) OR @PERIOD=0))
	  and pdl.Amount <> 0 and cus.no_ = emp.[School No_]
	  Group by PDL.Period 
              ,PDL.[Tax Year] 
	          ,pdl.[Payroll Group Code]
              ,pdl.[Payroll Date]
              ,pdl.[Original Appointment No_]
			  ,pdl.[Employee No_]
              ,pdl.[Pension 1]	  
	  		  ,CUS.[DfES Area]
              ,CUS.[Employer Pension Code]
              ,cus.[School DfES No_]
              ,cus.[PAYROLL REF]
              ,CUS.Name
              ,CUS.[Customer Type]
              ,CUS.[Employer Code]
              ,CUS.[Employer Pension Code]
-- Payroll Employee Information
	          ,PEM.[Join Date] 
              ,PEM.Forenames
              ,PEM.Surname 
              ,PEM.Title 
              ,PEM.[No_]
              ,CASE PEM.Sex WHEN 1 THEN 'F' ELSE 'M' END
              ,PEM.[NI Number]   
              ,CASE ISNUMERIC(replace(pem.[Address],' ',''))WHEN 1 THEN REPLACE(CONCAT(pem.[Address],' ',pem.[Address 2]),',',' ')
                ELSE pem.[Address] END 
              ,CASE ISNUMERIC(replace(pem.[Address],' ','')) WHEN 1 THEN ''
                   ELSE pem.[Address 2]END   
              ,PEM.[Post code]   
-- HR Employee Information 			  		  
              ,emp.Title
              ,emp.[First Name] 
              ,emp.[Last Name] 
              ,CASE emp.Sex  WHEN 1 THEN 'F' ELSE 'M' END
              ,emp.[No_]
              ,cast(emp.[Birth Date] as date) 
              ,CASE ISNUMERIC(replace(emp.[Address],' ',''))
               WHEN 1 THEN REPLACE(CONCAT(emp.[Address],' ',emp.[Address 2]),',',' ')
               ELSE emp.[Address] END  
              ,CASE ISNUMERIC(replace(emp.[Address],' ',''))
              WHEN 1 THEN '' ELSE emp.[Address 2] END 
              ,emp.[Post Code]
             ,emp.City 
             ,emp.County 
		     ,Replace(emp.[DFES No_],'/','') 	) as tmp





   -- GET ALL The Pension Payment Totals in the YTD
   -- Against Original Appointment Number.
Print('Placeholder -1')

	 
 Select  pdl.[Payroll Group Code]
        ,pdl.[Original Appointment No_]
		,cast(sum(CASE WHEN pen.[Pension Type] in (1,3) 
              and pen.[50_50 Scheme] = 0 
			  and pen.[Added Years]  = 0
			 THEN pdl.amount 
			 ELSE 0 
			 END )  as decimal(10,2)) as 'YTDEmployeeAmount'
        ,cast(sum(CASE WHEN pen.[Pension Type] in (1,3) 
              and pen.[50_50 Scheme] = 1 
			  and pen.[Added Years]  = 0 
			  THEN pdl.amount 
			  ELSE 0 
			  END ) as decimal(10,2)) as 'YTD5050EmployeeAmount'

        ,cast(sum(CASE WHEN pen.[Pension Type] in (2,4) 
              and pen.[50_50 Scheme] = 0 
			  and pen.[Added Years]  = 1 
			  THEN pdl.amount 
			  ELSE 0 
			  END )as decimal(10,2)) as 'YTDEmployeeAddedYearsAmount'


        ,cast(sum(CASE WHEN pen.[Pension Type] in (4) --and pen.[type] in (2,3) --AVC
			  and pen.[Added Years]  = 0 
			  and pdl.[Reference] like '%APC%'
			  THEN pdl.amount 
			  ELSE 0 
			  END )  as decimal(10,2)) as 'YTDEmployeeAPCAmount'

        ,cast(sum(CASE WHEN pen.[Pension Type] in (2,4) --and pen.[type] in (2,3) --AVC
			  and pen.[Added Years]  = 0 
			  and pdl.[Reference]  not like '%APC%'
			  THEN pdl.amount 
			  ELSE 0 
			  END ) as decimal(10,2))as 'YTDEmployeeAVCAmount'

	    ,cast(sum(pdl.amount) as decimal(10,2)) as 'YTDEmployeeTotalPensionAmount'

      -- Employers Amounts
	,cast(sum(CASE WHEN pen.[Pension Type] in (1,3) 
              and pen.[50_50 Scheme] = 0 
			  and pen.[Added Years]  = 0
			 THEN pdl.[Employer Amount]
			 ELSE 0 
			 END ) as decimal(10,2)) as 'YTDEmployerAmount'
        ,cast(sum(CASE WHEN pen.[Pension Type] in (1,3) 
              and pen.[50_50 Scheme] = 1 
			  and pen.[Added Years]  = 0 
			  THEN pdl.[Employer Amount]
			  ELSE 0 
			  END ) as decimal(10,2)) as 'YTD5050EmployerAmount'

        ,cast(sum(CASE WHEN pen.[Pension Type] in (2,4) 
              and pen.[50_50 Scheme] = 0 
			  and pen.[Added Years]  = 1 
			  THEN pdl.[Employer Amount] 
			  ELSE 0 
			  END ) as decimal(10,2)) as 'YTDEmployerAddedYearsAmount'
      ,cast(sum(CASE WHEN pen.[Pension Type] not in (2,4) 
              and pen.[50_50 Scheme] = 0 
			  and pen.[Added Years]  = 0 
			  and pdl.[Payment Reference] like '%APC%'
			  THEN pdl.[Employer Amount] 
			  ELSE 0 
			  END ) as decimal(10,2)) as 'YTDEmployerAPCAmount'

        ,cast(sum(CASE WHEN pen.[Pension Type] in (2,4)--  and pen.[type] in (2,3) --AVC
              and pen.[50_50 Scheme] = 0 
			  and pen.[Added Years]  = 0 
			  and  (pdl.[Reference] not like '%APC%')
			  THEN pdl.[Employer Amount] 
			  ELSE 0 
			  END ) as decimal(10,2)) as 'YTDEmployerAVCAmount'

	    ,cast(sum(pdl.[Employer Amount] ) as decimal(10,2)) as 'YTDEmployerTotalPensionAmount'
		,cast(sum(pdl.[Pensionable Pay])  as decimal(10,2)) As 'YTDPensionablePay'

	    ,cast(sum(CASE WHEN pen.[Pension Type] in (1,3) 
              and pen.[50_50 Scheme] = 0 
			  and pen.[Added Years]  = 0
			 THEN pdl.[Pensionable Pay]
			 ELSE 0 
			 END ) as decimal(10,2)) as 'YTDMainPensionablePay'
        ,cast(sum(CASE WHEN pen.[Pension Type] in (1,3) 
              and pen.[50_50 Scheme] = 1 
			  and pen.[Added Years]  = 0 
			  THEN pdl.[Pensionable Pay]
			  ELSE 0 
			  END ) as decimal(10,2)) as 'YTD5050PensionablePay'


    INTO #LGPSYTD
      From #LGPSMonthlySummary lg,
	      #Customer cus,  
		 [EPM$Pay Detail Line] Pdl
         INNER JOIN [EPM$Pension Scheme]   PEN  ON PDL.[Reference] = PEN.[Scheme No_]and   (pen.[Pension Type] in (1,2) and @Pensions = 'TPS' or  pen.[Pension Type] in (3,4) and  @Pensions= 'LGPS')
     where  cus.no_ = lg.PayDetailPayrollGroupCode
	  and pdl.[Payroll Group Code] = cus.no_
	  and pdl.[Pay Element Code] = 'PENSION'
	  and ( pdl.[Tax Year] = @TAXYEAR and ( (pdl.Period <= @PERIOD ) OR (@PERIOD=0) ))
--	  and pdl.[Employee No_] not like '%R%'
	  and pdl.[Original Appointment No_] = lg.[PayDetailOriginalAppointmentNumber]
	  Group by pdl.[Payroll Group Code],
	                pdl.[Original Appointment No_]

Print('Placeholder 0')
-- Build the PEN8 Figures

/* NOW Build the PEN8 Figures */

 SELECT * INTO  #Pen8AppointmentInfo FROM (
    SELECT  distinct 
	             @PeriodStart     as 'PeriodStart'
                ,@PeriodEnd       as 'PeriodEnd'
                ,cast(0000.00 as decimal)    as 'Pen8PeriodDays'
	            ,pr.TaxPeriod
	            ,pr.TaxYear
	            ,pr.AppointmentFirstDayOfMonth
	            ,pr.AppointmentLastDayOfMonth
	            ,pr.DaysInMonth
	            ,app.[Effective Date]
                ,app.[End Date]
	            ,app.[Original Appointment]



--  Effective Date Between Then Take effective Date.
--  Effective Date before First Date and End Date after first Date take First Date



		,cast( CASE 
		    WHEN (app.[Effective Date] between pr.AppointmentFirstDayOfMonth and pr.AppointmentLastDayOfMonth )
              THEN  
			    app.[Effective Date] 	

            WHEN app.[End Date] between  pr.AppointmentFirstDayOfMonth and pr.AppointmentLastDayOfMonth 
			  THEN 
			    pr.AppointmentFirstDayOfMonth

		    WHEN app.[Effective Date] < pr.AppointmentFirstDayOfMonth and app.[End Date] > pr.AppointmentLastDayOfMonth 
		      THEN 
				pr.AppointmentFirstDayOfMonth

		    WHEN app.[Effective Date] < pr.AppointmentFirstDayOfMonth and app.[End Date] = '1753-01-01'
		      THEN 
				pr.AppointmentFirstDayOfMonth
		   		  
		    END as date) as 'CalcStart'	
--- END Calc Start 

	       ,CAST( CASE WHEN (app.[End Date] between pr.AppointmentFirstDayOfMonth and pr.AppointmentLastDayOfMonth )
                    THEN  
					  app.[End Date]
			      WHEN app.[End Date] > pr.AppointmentLastDayOfMonth and app.[Effective Date] < pr.AppointmentLastDayOfMonth
			 		THEN 
					  pr.AppointmentLastDayOfMonth
                 WHEN app.[End Date] = '1753-01-01'
				 THEN 
				   pr.AppointmentLastDayOfMonth
	         END as date) as 'CalcEnd'
	  ,cast('000' as integer) as AppointmentDaysInMonth
	  ,cast('000' as decimal(10,2))      as 'CalculatedMonthlySalary'
	  ,cast('000' as decimal(10,2))      as 'CalculatedWeeksWorkedMonthlySalary'
	  ,Cast('XXXXXXXXXX'  as varchar(10))        as 'CalculationFormula'

	  ,cast('000' as Decimal(10,2))      as 'Overtime'
	  ,cast('000' as decimal(10,2))      as 'CalculatedMonthlySalaryIncludingOvertime'
      ,app.[No_] as 'AppointmentNumber'
      ,app.[Customer No_] as 'CustomerNumber'
      ,app.[Employee No_] as 'EmployeeNumber'
      ,app.[Appointment Date]
	  ,app.Weeks as 'AppWeeks'
	  ,app.[Full Time Weeks] as 'AppFullTimeWeeks'
      ,cast(app.[Full Time Hours] as decimal(16,2))	   					  as 'FullTimeHours'
      ,cast(ISNULL(APP.[Total Hours],0) as decimal (10,2))				  as 'NormalHoursperWeek'   
      ,cast(app.[Salary Part Time]/nullif(app.[Salary Full Time],0) as Decimal(10,2)) as 'PartTimePercentage' 
     , CASE APP.[Full _ Part Time] WHEN 1 THEN 'Y' ELSE 'N' END		    as 'PTIndicator'
	  ,cast( 
				 CASE WHEN app.[Full _ Part Time] = 1   THEN  -- Part Time
                 app.[Salary Part Time] 
                 + CASE PE1.Pension WHEN 1 THEN  app.[Allowance Part Time Amount 1]  ELSE 0 END				 
			     + CASE PE2.Pension WHEN 1 THEN  app.[Allowance Part Time Amount 2]  ELSE 0 END  
				 + CASE PE3.Pension WHEN 1 THEN  app.[Allowance Part Time Amount 3]  ELSE 0 END
				 + CASE PE4.Pension WHEN 1 THEN  app.[Allowance Part Time Amount 4]  ELSE 0 END
				 + app.[TLR Amount]
				 + app.[Safeguard Total]
				 ELSE 0 END  
				 as Decimal(10,2))  as 'PartTimeAnnualPensionableSalary'
			,   cast( 
                 app.[Salary Full Time]
                 + CASE PE1.Pension WHEN 1 THEN  app.[Allowance Full Time Amount 1] ELSE 0 END				 
			     + CASE PE2.Pension WHEN 1 THEN  app.[Allowance Full Time Amount 2] ELSE 0 END  
				 + CASE PE3.Pension WHEN 1 THEN  app.[Allowance Full Time Amount 3] ELSE 0 END
				 + CASE PE4.Pension WHEN 1 THEN  app.[Allowance Full Time Amount 4] ELSE 0 END
				 + app.[TLR Amount]
				 + app.[Safeguard Total]
				 as Decimal(10,2))  as 'FullTimeAnnualPensionableSalary'   
				 , 'N' as 'Month13'  
    FROM #LGPSYTD ld,
         #Periods pr,
         [EPM$Appointment] app
     LEFT JOIN [EPM$Pay Element]pe1 on app.[Allowance Code 1] = pe1.code and pe1.Pension = 1
	 LEFT JOIN [EPM$Pay Element]pe2 on app.[Allowance Code 2] = pe2.code and pe2.Pension = 1
	 LEFT JOIN [EPM$Pay Element]pe3 on app.[Allowance Code 3] = pe3.code and pe3.Pension = 1
	 LEFT JOIN [EPM$Pay Element]pe4 on app.[Allowance Code 4] = pe4.code and pe4.NI = 1    
  WHERE ((app.[End Date] BETWEEN @PEN8PeriodStart and @PeriodEnd) or 
         (app.[effective date] between @PEN8PeriodStart and @PeriodEnd))
          and  app.[Original Appointment] = ld.[Original Appointment No_]
		  and (isNull(app.[Resignation Date],'1753-01-01') ='1753-01-01'  OR app.[Resignation Date] > @PeriodStart)
--		  and app.[Employee No_] not like '%R%'
UNION
select 
/*  For the 13th month back the @Pen8_365days from the End Date of Current Period  to place in CalcStart column
      and the CalcEnd will be the correct PeriodEnd from the Period13 table */
 distinct 
	             @PeriodStart     as 'PeriodStart'
                ,@PeriodEnd       as 'PeriodEnd'
                ,cast(0000.00 as decimal)    as 'Pen8PeriodDays'
	            ,pr.TaxPeriod
	            ,pr.TaxYear
	            ,pr.AppointmentFirstDayOfMonth
	            ,pr.AppointmentLastDayOfMonth
	            ,pr.DaysInMonth
	            ,app.[Effective Date]
                ,app.[End Date]
	            ,app.[Original Appointment]
			    ,(DATEADD(DD,1,DATEADD(MM,-12,app.[End Date]))) as 'CalcStart'	
	       ,pr.AppointmentLastDayOfMonth as 'CalcEnd'
	  ,cast('000' as integer) as AppointmentDaysInMonth
	  ,cast('000' as decimal(10,2))      as 'CalculatedMonthlySalary'
	  ,cast('000' as decimal(10,2))      as 'CalculatedWeeksWorkedMonthlySalary'
	  ,Cast('XXXXXXXXXX'  as varchar(10))        as 'CalculationFormula'

	  ,cast('000' as Decimal(10,2))      as 'Overtime'
	  ,cast('000' as decimal(10,2))      as 'CalculatedMonthlySalaryIncludingOvertime'
      ,app.[No_] as 'AppointmentNumber'
      ,app.[Customer No_] as 'CustomerNumber'
      ,app.[Employee No_] as 'EmployeeNumber'
      ,app.[Appointment Date]
	  ,app.Weeks as 'AppWeeks'
	  ,app.[Full Time Weeks] as 'AppFullTimeWeeks'
      ,cast(app.[Full Time Hours] as decimal(16,2))	   					  as 'FullTimeHours'
      ,cast(ISNULL(APP.[Total Hours],0) as decimal (10,2))				  as 'NormalHoursperWeek'   
      ,cast(app.[Salary Part Time]/nullif(app.[Salary Full Time],0) as Decimal(10,2)) as 'PartTimePercentage' 
     , CASE APP.[Full _ Part Time] WHEN 1 THEN 'Y' ELSE 'N' END		    as 'PTIndicator'
	 /*	Now to get the correct Salary for the 13th Period need to do an internal select to retrieve for the correct Appointment row		*/
	  ,cast( 
				 CASE WHEN app.[Full _ Part Time] = 1   THEN  -- Part Time
                 (select app2.[Salary Part Time]
                                   + CASE PE1.Pension WHEN 1 THEN  app2.[Allowance Full Time Amount 1] ELSE 0 END				 
			                       + CASE PE2.Pension WHEN 1 THEN  app2.[Allowance Full Time Amount 2] ELSE 0 END  
				                   + CASE PE3.Pension WHEN 1 THEN  app2.[Allowance Full Time Amount 3] ELSE 0 END
				                   + CASE PE4.Pension WHEN 1 THEN  app2.[Allowance Full Time Amount 4] ELSE 0 END
				                   + app2.[TLR Amount]
				                   + app2.[Safeguard Total]  
                     from [EPM$Appointment] app2
                                             LEFT JOIN [EPM$Pay Element]pe1 on app2.[Allowance Code 1] = pe1.code and pe1.Pension = 1
	                                         LEFT JOIN [EPM$Pay Element]pe2 on app2.[Allowance Code 2] = pe2.code and pe2.Pension = 1
											 LEFT JOIN [EPM$Pay Element]pe3 on app2.[Allowance Code 3] = pe3.code and pe3.Pension = 1
											 LEFT JOIN [EPM$Pay Element]pe4 on app2.[Allowance Code 4] = pe4.code and pe4.NI = 1    
					where app2.[Original Appointment]= ld.[Original Appointment No_]
                        and app2.[Effective Date] < DATEADD(DD,1,DATEADD(MM,-12,app.[End Date])) and app2.[End Date] > DATEADD(DD,1,DATEADD(MM,-12,app.[End Date])))
				 ELSE 0 END  
				 as Decimal(10,2))  as 'PartTimeAnnualPensionableSalary'
			   ,cast((select app2.[Salary Full Time]
                                   + CASE PE1.Pension WHEN 1 THEN  app2.[Allowance Full Time Amount 1] ELSE 0 END				 
			                       + CASE PE2.Pension WHEN 1 THEN  app2.[Allowance Full Time Amount 2] ELSE 0 END  
				                   + CASE PE3.Pension WHEN 1 THEN  app2.[Allowance Full Time Amount 3] ELSE 0 END
				                   + CASE PE4.Pension WHEN 1 THEN  app2.[Allowance Full Time Amount 4] ELSE 0 END
				                   + app2.[TLR Amount]
				                   + app2.[Safeguard Total]  
                     from [EPM$Appointment] app2
                                             LEFT JOIN [EPM$Pay Element]pe1 on app2.[Allowance Code 1] = pe1.code and pe1.Pension = 1
	                                         LEFT JOIN [EPM$Pay Element]pe2 on app2.[Allowance Code 2] = pe2.code and pe2.Pension = 1
											 LEFT JOIN [EPM$Pay Element]pe3 on app2.[Allowance Code 3] = pe3.code and pe3.Pension = 1
											 LEFT JOIN [EPM$Pay Element]pe4 on app2.[Allowance Code 4] = pe4.code and pe4.NI = 1    
					where app2.[Original Appointment]= ld.[Original Appointment No_]
                       and app2.[Effective Date] < DATEADD(DD,1,DATEADD(MM,-12,app.[End Date])) and app2.[End Date] > DATEADD(DD,1,DATEADD(MM,-12,app.[End Date]))) 
                    as Decimal(10,2))  as 'FullTimeAnnualPensionableSalary'
				 , 'Y' as 'Month13'  
    FROM #LGPSYTD ld,
         #Period13 pr,
         [EPM$Appointment] app
     LEFT JOIN [EPM$Pay Element]pe1 on app.[Allowance Code 1] = pe1.code and pe1.Pension = 1
	 LEFT JOIN [EPM$Pay Element]pe2 on app.[Allowance Code 2] = pe2.code and pe2.Pension = 1
	 LEFT JOIN [EPM$Pay Element]pe3 on app.[Allowance Code 3] = pe3.code and pe3.Pension = 1
	 LEFT JOIN [EPM$Pay Element]pe4 on app.[Allowance Code 4] = pe4.code and pe4.NI = 1    
   WHERE ((app.[End Date] BETWEEN @PeriodStart and @PeriodEnd_1) 
          and (isNull(app.[Resignation Date],'1753-01-01') <> '1753-01-01'))
          and  app.[Original Appointment] = ld.[Original Appointment No_]
		  and app.[Appointment Date] < @PEN8PeriodStart
		  and (app.[Resignation Date] > @PeriodStart)
--		  and app.[Employee No_] not like '%R%'
		  ) as tmp2
 


            Update #Pen8AppointmentInfo 
               SET AppointmentDaysInMonth = (Select count(dm.dimdate)
                                               from DimDate_SSRS dm 
								              where dm.DimDate between CalcStart and CalcEnd)
Print('Placeholder 1')

          UPDATE #Pen8AppointmentInfo
                SET CalculatedMonthlySalary = (FullTimeAnnualPensionableSalary    /12 ) /nullif(DaysInMonth,0)* AppointmentDaysInMonth
				       ,CalculatedWeeksWorkedMonthlySalary =  ((FullTimeAnnualPensionableSalary /12 ) * (AppWeeks/nullif(AppFullTimeWeeks,0))  ) /nullif(DaysInMonth,0)* AppointmentDaysInMonth
	                   ,CalculationFormula  = CONCAT(cast(AppointmentDaysInMonth as integer),'/',cast(DaysInMonth as integer))
--

Print('Placeholder 2')


--Select * from #Pen8AppointmentInfo 


         Select [Original Appointment]
		       ,@Pen8_365Days as 'Pen8_365Days'
			   ,@PEN8PeriodStart as 'Pen8PeriodStart'
		       ,sum(appointmentdaysinmonth)  as 'AppointmentDaysInPeriod'
		       ,sum(CalculatedMonthlySalary) as 'TempPEN8Amount' 
			   ,sum(CalculatedWeeksWorkedMonthlySalary ) as 'TempPen8WeeksWorkedAmount' 
			   ,cast(000000000000.00 as decimal(10,2))  as 'AnnualisedPen8Amount'
			   ,cast(000000000000.00 as decimal(10,2))  as 'AnnualisedPen8WeeksWorkedAmount'
	      INTO #PEN8_DATA_LOCAL from #Pen8AppointmentInfo 
		  GROUP BY [Original Appointment]
 


 UPDATE #PEN8_DATA_LOCAL SET AnnualisedPen8Amount = cast((Pen8_365Days/nullif(AppointmentDaysInPeriod,0))*TempPEN8Amount as decimal(10,2))
 UPDATE #PEN8_DATA_LOCAL SET AnnualisedPen8WeeksWorkedAmount = cast((Pen8_365Days/nullif(AppointmentDaysInPeriod,0))*TempPen8WeeksWorkedAmount as decimal(10,2))
  /* MSS possible Change 
  The above appears to be there to allow for Leap Years but I cannot see a reason why it would ever be other than 365/365 or 366/366?? 
  This will be an issue when doing 13 Periods... so need to use a different variable for this... */
 --        UPDATE #PEN8_DATA_LOCAL SET AnnualisedPen8Amount = cast(TempPEN8Amount as decimal(10,2))
--        UPDATE #PEN8_DATA_LOCAL SET AnnualisedPen8WeeksWorkedAmount = cast(TempPen8WeeksWorkedAmount as decimal(10,2))

 --Select * from #PEN8_DATA_LOCAL

/* MSS: 10Jan19
        Prior to my changes the line:
		     SET #LGPSMonthlySummary.Pen8FTEAmount = #PEN8_DATA_LOCAL.TempPEN8Amount
		had been commented out and replaced by:
		     SET #LGPSMonthlySummary.Pen8FTEAmount = #PEN8_DATA_LOCAL.AnnualisedPen8Amount

		The Users need to see BOTH the Annualised FTE and the straight FTE so I have utilised a field that although being in the Query 
		is currently NOT being used - they have been having problems with Report Builder adding a NEW FIELD which is why we went for this route - hopefully temporarily!! 
		The Annualised figure now resides in the  [Pen8WeeksWorkedAmount] with title on Report of ANNUALISED_PEN8_FTE
		The [Pen8FTEAmount] entitled FTE_FINAL_PAY_ANNUAL returns to be the Actual amount added from the sum of the Months in question...
		which is in line with the Pen8Calculator Report
        It makes more sense of the name used to give the Actual figure rather than the Annualised here!
*/

         UPDATE #LGPSMonthlySummary
		 SET #LGPSMonthlySummary.Pen8FTEAmount = #PEN8_DATA_LOCAL.TempPEN8Amount
                ,#LGPSMonthlySummary.AnnualisedPen8FTEAmount = #PEN8_DATA_LOCAL.AnnualisedPen8Amount
                ,#LGPSMonthlySummary.Pen8WeeksWorkedAmount = #PEN8_DATA_LOCAL.AnnualisedPen8WeeksWorkedAmount
           FROM #LGPSMonthlySummary INNER JOIN #PEN8_DATA_LOCAL ON #LGPSMonthlySummary.PayDetailOriginalAppointmentNumber= #PEN8_DATA_LOCAL.[Original Appointment]     
/*        
         UPDATE #pLGPSMonthlySummary
		 SET #LGPSMonthlySummary.Pen8FTEAmount = #PEN8_DATA_LOCAL.AnnualisedPen8Amount
                ,#LGPSMonthlySummary.Pen8WeeksWorkedAmount = #PEN8_DATA_LOCAL.AnnualisedPen8WeeksWorkedAmount
*/
        --    SET #LGPSMonthlySummary.Pen8FTEAmount = #PEN8_DATA_LOCAL.TempPEN8Amount


         UPDATE #LGPSMonthlySummary 
            SET MainEmployeeContributionsYTD      = ytd.YTDEmployeeAmount
		       ,MainEmployerContributionsYTD          = ytd.YTDEmployerAmount
			   ,EmployerTotalPensionAmountYTD      = ytd.YTDEmployerTotalPensionAmount
	           ,[5050EmployeeContributionYTD]         = ytd.[YTD5050EmployeeAmount]
		       ,[5050EmployerContributionYTD]          = ytd.[YTD5050EmployerAmount]
		       ,EmployeeAddedYearsYTD                  = ytd.YTDEmployeeAddedYearsAmount
		       ,EmployerAddedYearsYTD                   = ytd.YTDEmployerAddedYearsAmount
			   ,MainCumlativePensionablePayYTD      = ytd.YTDMainPensionablePay
			   ,[5050PensionablePayYTD]                  = ytd.YTD5050PensionablePay
			   ,EmployeeAVCYTD                             = ytd.YTDEmployeeAVCAmount
			   ,EmployerAVCYTD                    = ytd.YTDEmployerAVCAmount
			   ,EmployeeAPCYTD                    = ytd.YTDEmployeeAPCAmount
			   ,EmployerAPCYTD                    = ytd.YTDEmployerAPCAmount

          FROM #LGPSMonthlySummary  ms
                INNER JOIN #LGPSYTD  ytd ON ms.PayDetailOriginalAppointmentNumber= ytd.[Original Appointment No_]

       Update #LGPSMonthlySummary 
	     Set PeriodEmployeePensionTotalsOK = 'N'
		 WHERE [Period50-50EmployeeAmount]
		     + PeriodEmployeeAmount 
			 + PeriodEmployeeAPCAmount 
			 + PeriodEmployeeAVCAmount  
			 + PeriodEmployeeAddedYearsAmount <> PeriodEmployeeTotalPensionAmount


    /*   Update #LGPSMonthlySummary 
	     Set YTDEmployeePensionTotalsOK = 'N'
		 WHERE ytd
		     + PeriodEmployeeAmount 
			 + PeriodEmployeeAPCAmount 
			 + PeriodEmployeeAVCAmount  
			 + PeriodEmployeeAddedYearsAmount <> PeriodEmployeeTotalPensionAmount
			 */


-- Populate Consolidated Original Appointment Info
 select * INTO  #OriginalAppointmentInfo FROM (

 Select 
   app.[On Maternity]                                                 as 'AppointmentOnLeave',
   APP.[Original Appointment]										  as 'AppointmentOriginalAppointment',
   app.no_                                                                  as 'AppointmentNo',
   ms.[DfES Area]                                                     as 'AppointmentCustomerDfesArea',
   app.[Customer No_]                                                 as 'ApptCustNo',
   ms.PayDetailEmployeeNumber                                         as 'AppointmentPayDetailEmployeeNumber',
   
   cast(app.[Effective Date]  as date )                               as 'AppointmentEffectiveDate',

   cast(app.[End Date] as date )                                      as 'AppointmentEndDate',
   nullif(cast(app.[Resignation Date]   as date),'1753-01-01')        as 'AppointmentResignationDate',
   cast(app.[Resignation Reason] as Varchar(100))                     as 'AppointmentResignationReason',
   cast(app.[Appointment Date]  as date)                              as 'AppointmentDate',
   cast(app.[Opted out of LGPS]   as date)							  as 'AppointmentOptOutDate',
   cast(app.[date joined lgps] as date)								  as 'DateJoinedLGPS',
   --case when cast(app.[date joined lgps] as date) > DATEADD(month,-1,GETDATE())     then    cast(app.[date joined lgps] as date) else        cast('1900-01-01' as date)   end               as 'DateJoinedLGPS',
   app.[Re Issued From]                                               as 'AppointmentReissuedFrom',
   app.[Re Issued To]                                                 as 'AppointmentReissuedTo',
   cast(app.Weeks  as decimal(10,2))                                  as 'AppointmentWeeks',
   app.[Full Time Weeks]                                              as 'AppointmentFullTimeWeeks',
   Cast(Replace(app.[Job Description],',',' ') as varchar(20))        as 'AppointmentJobDescription',
   app.[Pension 1]                                                    as 'AppointmentPension1',
   app.[Entitlement Weeks]                                            as 'AppointmentEntitlementWeeks',
   cast(app.[Total Hours] * app.Weeks /nullif(app.[Full Time Weeks],0) as decimal(10,2))     As 'AppointmentAveragedHours' ,

   CASE APP.[Full _ Part Time] WHEN 1 THEN 'PT' ELSE 'FT' END		  as 'AppointmentPTIndicator',
   CASE APP.[Full _ Part Time] WHEN 1 THEN 'Y' ELSE '' END		      as 'AppointmentLGSSPTIndicator',
   ''           as 'Scheme Status',
   cast(APP.[Salary Full Time] as decimal(16,2))                      as 'AppointmentFullTimeSalary',
   cast(app.[Full Time Hours] as decimal(16,2))	   					  as 'AppointmentFullTimeHours',

   --v1.5.080519.144910
   cast(app.[Total Hours] as decimal(16,2))							  as 'AppointmentTotalHours',
   --v1.5.080519.144910

   CASE APP.[Full _ Part Time]  WHEN 1 THEN  cast(cast(app.[Full Time Hours] as decimal(5,2)) as Varchar(5)) ELSE ''  END  as 'LGSSWHOLETIMEEQUIVELANTHOURS',
   cast(App.[Salary Part Time] as decimal(16,2))					  as 'AppointmentSalaryParttime',
   cast(App.[Salary Incl_ Allowances] as decimal(16,2))				  as 'AppointmentSalaryIncAllowances', 

   cast( app.[Salary Full Time] + app.[Allowance Full Time Amount 1]
			     + app.[Allowance Full Time Amount 2]
				 + app.[Allowance Full Time Amount 3]
				 + app.[Allowance Full Time Amount 4]
				 + app.[TLR Amount]
				 + app.[Safeguard Total] as Decimal(10,2))          as 'AppointmentFullTimeSalaryIncludingAllowances',
                cast( 
				 CASE WHEN app.[Full _ Part Time] = 1   THEN  -- Part Time
                 app.[Salary Part Time] 
                 + CASE PE1.Pension WHEN 1 THEN  app.[Allowance Part Time Amount 1]  ELSE 0 END				 
			     + CASE PE2.Pension WHEN 1 THEN  app.[Allowance Part Time Amount 2]  ELSE 0 END  
				 + CASE PE3.Pension WHEN 1 THEN  app.[Allowance Part Time Amount 3]  ELSE 0 END
				 + CASE PE4.Pension WHEN 1 THEN  app.[Allowance Part Time Amount 4]  ELSE 0 END
				 + app.[TLR Amount]
				 + app.[Safeguard Total]
				 ELSE 0 END  
				 as Decimal(10,2))  as 'AppointmentPartTimeAnnualPensionableSalary'
			,   cast( 
                 app.[Salary Full Time]
                 + CASE PE1.Pension WHEN 1 THEN  app.[Allowance Full Time Amount 1] ELSE 0 END				 
			     + CASE PE2.Pension WHEN 1 THEN  app.[Allowance Full Time Amount 2] ELSE 0 END  
				 + CASE PE3.Pension WHEN 1 THEN  app.[Allowance Full Time Amount 3] ELSE 0 END
				 + CASE PE4.Pension WHEN 1 THEN  app.[Allowance Full Time Amount 4] ELSE 0 END
				 + app.[TLR Amount]
				 + app.[Safeguard Total]
				 as Decimal(10,2))  as 'AppointmentFullTimeAnnualPensionableSalary',

   cast([Salary Part Time]/nullif([Salary Full Time],0) as Decimal(10,2)) as 'AppointmentPartTimePercentage' ,
   cast(ISNULL(APP.[Total Hours],0) as decimal (10,2))				  as 'AppointmentNormalHoursperWeek',
   cast('1753-01-01' as date) as 'AppointmentPartTimeHoursEffectiveFrom',
   cast('1753-01-01' as date) as 'PensionableSalaryEffectiveFrom' ,
  
   CASE WHEN APP.[Full _ Part Time] = 1 THEN
   CASE
		WHEN app.[Pay Calculation Method]=12 THEN
		      Cast(CAST(app.[Total Hours]*app.[Weeks]/nullif([Entitlement Weeks],0)as Decimal(5,2))as Varchar(5))
			ELSE
			  Cast(Cast(app.[Total Hours]*app.[Weeks]/nullif([Full Time Weeks],0) As Decimal (5,2)) as Varchar(5))			
			END  
  ELSE
   ''

  END 
    as'LGSSPartTimeHours',

 
 --pen.[50_50 Scheme] as 'Appointment50_50Scheme',
  
 --  Cast(PEN.[Employer Contribution]									  as decimal(16,2))  as 'Employer Contribution Percentage',
   cast(app.[Effective Date]  as date )                               as 'RowHoursEffectiveFrom',
   cast(app.[Effective Date]  as date )                               as 'RowWeeksEffectiveFrom',
   cast(app.[Effective Date]  as date )                               as 'RowSalaryEffectiveFrom',
   cast('0000000.00'  as Decimal(9,2))                                 as 'RowOldHours',
   cast('0000000.00'  as Decimal(9,2))                                 as 'RowOldWeeks',
   cast('0000000.00'  as Decimal(9,2))                                 as 'RowOldActual',
   cast('0000000.00'  as Decimal(9,2))                                 as 'RowOldFTE',
   cast('0000000.00'  as Decimal(9,2))                                 as 'OldAppFullTimeWeeks',
   cast('0000000.00'  as Decimal(9,2))                                 as 'OldAppFullTimeHours',
   cast('0000000.00'  as Decimal(9,2))                                 as 'OldAppAveragedHours',
   cast('0000000.00'  as Decimal(9,2))                                 as 'TaxableEarningsForPeriod',
   cast('Current'  as varchar(20)) as 'RowStatus'
   
FROM #LGPSMonthlySummary ms,
     [EPM$Appointment]   APP 
     LEFT JOIN [EPM$Pay Element]pe1 on app.[Allowance Code 1] = pe1.code and pe1.Pension = 1
	 LEFT JOIN [EPM$Pay Element]pe2 on app.[Allowance Code 2] = pe2.code and pe2.Pension = 1
	 LEFT JOIN [EPM$Pay Element]pe3 on app.[Allowance Code 3] = pe3.code and pe3.Pension = 1
	 LEFT JOIN [EPM$Pay Element]pe4 on app.[Allowance Code 4] = pe4.code and pe4.NI = 1    
  -- LEFT JOIN [EPM$Pension Scheme]   PEN  ON UPPER(pdl.reference )  = UPPER(PEN.[Scheme No_])
  where ms.PayDetailOriginalAppointmentNumber  = app.[Original Appointment]
    and app.[Effective Date] <= @PeriodEnd
	
	and app.no_ = (select max(app2.no_) from [EPM$Appointment] APP2 where app2.[Original Appointment] = app.[Original Appointment]
	               and app2.[Effective Date] <= @PeriodEnd)
	
   ) as tmp

   

  update  LG set lg.AppointmentResignationReason= replace([Description],',',' ')
   FROM  #OriginalAppointmentInfo LG  left join [EPM$Dictionary by Territory] DI  on lg.AppointmentResignationReason = di.Code and lg.AppointmentCustomerDfesArea = di.Territory
   where TYPE = 'RESIGNATION'

/* MSS: Change to exclude reductions from Taxable Earnings - It needs to be the Gross Earnings - Type <> 1 achieves this.
The %R% throughout is to prevent  'after' resignaion adjustments being included within the figures incorrectly 
 */
      

  update #OriginalAppointmentInfo set TaxableEarningsForPeriod =   (SELECT sum(amount)
                                                                     FROM [EPM$Pay Detail Line] pdl
                                                                         ,[EPM$Pay Element] pe
                                                                    where pe.Tax = 1
                                                                     and pe.Code = pdl.[Pay Element Code]
                                                                     and pdl.[Tax Year] = @TAXYEAR
													                 -- and pdl.Period = @PERIOD
													                 and ( (pdl.Period = @PERIOD) OR (@PERIOD=0) )
													                 and pdl.[Original Appointment No_] = #OriginalAppointmentInfo.AppointmentOriginalAppointment
																	 -- and pdl.[Employee No_] not like '%R%'
																	 and pdl.[Type] <> 1
													                 and pdl.[Employee No_] = #OriginalAppointmentInfo.AppointmentPayDetailEmployeeNumber)
											 

--
-- Now Lets Work out the Effective Dates for the Part Time Hours.
--


   Select app.[Original Appointment],
          app.[Effective Date],
		  app.[Full _ Part Time] ,
		  cast( app.[Salary Full Time]
                 + CASE PE1.Pension WHEN 1 THEN  app.[Allowance Full Time Amount 1] ELSE 0 END				 
			     + CASE PE2.Pension WHEN 1 THEN  app.[Allowance Full Time Amount 2] ELSE 0 END  
				 + CASE PE3.Pension WHEN 1 THEN  app.[Allowance Full Time Amount 3] ELSE 0 END
				 + CASE PE4.Pension WHEN 1 THEN  app.[Allowance Full Time Amount 4] ELSE 0 END
				 + app.[TLR Amount]
				 + app.[Safeguard Total]
				 as Decimal(10,2))  as 'FullTimeAnnualPensionableSalary'  ,
            CASE WHEN APP.[Full _ Part Time] = 1 THEN
                CASE
		          WHEN app.[Pay Calculation Method]=12 THEN
		              Cast(CAST(app.[Total Hours]*app.[Weeks]/nullif([Entitlement Weeks],0)as Decimal(5,2))as Varchar(5))
			      ELSE
			  Cast(Cast(app.[Total Hours]*app.[Weeks]/nullif([Full Time Weeks],0) As Decimal (5,2)) as Varchar(5))			
			      END  
               ELSE
               ''
               END as 'LGSSPartTimeHours'				  
     into #HistoricalAppointmentInfo
     from #OriginalAppointmentInfo OAI,
	       [EPM$Appointment] app 
		      LEFT JOIN [EPM$Pay Element]pe1 on app.[Allowance Code 1] = pe1.code and pe1.Pension = 1
	          LEFT JOIN [EPM$Pay Element]pe2 on app.[Allowance Code 2] = pe2.code and pe2.Pension = 1
	          LEFT JOIN [EPM$Pay Element]pe3 on app.[Allowance Code 3] = pe3.code and pe3.Pension = 1
	          LEFT JOIN [EPM$Pay Element]pe4 on app.[Allowance Code 4] = pe4.code and pe4.NI = 1  
      WHERE OAI.AppointmentOriginalAppointment = app.[Original Appointment]


   Update #OriginalAppointmentInfo 
   SET AppointmentPartTimeHoursEffectiveFrom =      
   (Select MIN(hi.[Effective Date])
         from #HistoricalAppointmentInfo hi
		   Where hi.[Original Appointment] = #OriginalAppointmentInfo.AppointmentOriginalAppointment
			 and hi.[Full _ Part Time] = 1 
			 and hi.LGSSPartTimeHours =  #OriginalAppointmentInfo.LGSSPartTimeHours
			 and hi.[Effective Date] <= #OriginalAppointmentInfo.AppointmentEffectiveDate
			 and hi.[Effective Date] >= isnull((SELECT MAX(hi2.[Effective Date])
                                                   from #HistoricalAppointmentInfo hi2
		                                          Where hi2.[Original Appointment] = #OriginalAppointmentInfo.AppointmentOriginalAppointment
			                                        and hi2.[Full _ Part Time]  = 1 
			                                        and hi2.LGSSPartTimeHours <> #OriginalAppointmentInfo.LGSSPartTimeHours
			                                        and hi2.[Effective Date] < #OriginalAppointmentInfo.AppointmentEffectiveDate
			                                          ),hi.[Effective Date]))
	   where #OriginalAppointmentInfo.AppointmentLGSSPTIndicator = 'Y'


------------------------------------------------------------------------------------------------------------------------------------------------
--v1.3.280319.160959
--Start 
						
   -- ORIGINAL - DO NOT DELETE
   --Update  oai
   --SET AppointmentPartTimeHoursEffectiveFrom = a.[Effective Date]
   --FROM #OriginalAppointmentInfo oai
   --inner join [EPM$Appointment] a ON oai.AppointmentNo = a.No_
   --inner join [EPM$Appointment] a2 ON oai.AppointmentOriginalAppointment = a2.No_
	  -- where a.[Total Hours] = a.[Full Time Hours] 

CREATE TABLE  #LastAppointmentRec(
				 ApptNo nvarchar(20),
				 OrigAppNo nvarchar(20),
				 AppFTHours decimal(38,20),
				 AppTotHours decimal(38,20),
				 AppWeeks decimal(38,20))

   INSERT INTO   #LastAppointmentRec(ApptNo, OrigAppNo, AppFTHours, AppTotHours, AppWeeks)
   SELECT		oai.AppointmentNo, oai.AppointmentOriginalAppointment, oai.AppointmentFullTimeHours, oai.AppointmentTotalHours, oai.AppointmentWeeks
   FROM			#OriginalAppointmentInfo oai
   WHERE		oai.AppointmentNo = (select max(sub.No_) from [EPM$Appointment] sub where sub.[Original Appointment] = oai.AppointmentOriginalAppointment)
   AND			oai.AppointmentEffectiveDate <= @PeriodEnd

   UPDATE		oai
   SET			AppointmentPartTimeHoursEffectiveFrom = 
                (select min(appt.[Effective Date]) 
				 from [EPM$Appointment] appt 
				 where appt.[Original Appointment] = oai.AppointmentOriginalAppointment
				 
				 --v1.4.080519.132707
				 --and appt.[Full Time Hours] = lar.AppFTHours
				 --and appt.Weeks = lar.AppWeeks)
				 --v1.5.080519.144910
				 --and round(appt.[Full Time Hours],2) = round(lar.AppFTHours,2)
				 and round(appt.[Total Hours],2) = round(lar.AppTotHours,2)
				 --v1.5.080519.144910
				 and round(appt.Weeks,2) = round(lar.AppWeeks,2))
                 --v1.4.080519.132707

   FROM			#OriginalAppointmentInfo oai
				,#LastAppointmentRec lar
   WHERE		lar.OrigAppNo = oai.AppointmentOriginalAppointment 
   AND			oai.AppointmentEffectiveDate <= @PeriodEnd	
				
   --v1.5.080519.144910
   -- MSS update to cope with where DateJoinedLGPS is less than the date the School Joined the Scheme! */
   UPDATE oai  
   SET		AppointmentPartTimeHoursEffectiveFrom = cs.[EPM Payroll Effectivefrom Date]
   FROM		#OriginalAppointmentInfo oai join  #Customer cs on oai.ApptCustNo = cs.[No_]
   WHERE	AppointmentPartTimeHoursEffectiveFrom < cs.[EPM Payroll Effectivefrom Date]
   --v1.5.080519.144910

--End
--v1.3.280319.160959
------------------------------------------------------------------------------------------------------------------------------------------------


   Update #OriginalAppointmentInfo 
   SET PensionableSalaryEffectiveFrom =      
    isnull((Select MIN(hi.[Effective Date])
         from #HistoricalAppointmentInfo hi
		   Where hi.[Original Appointment] = #OriginalAppointmentInfo.AppointmentOriginalAppointment
			 and hi.FullTimeAnnualPensionableSalary=  #OriginalAppointmentInfo.AppointmentFullTimeAnnualPensionableSalary
			 and hi.[Effective Date] <= #OriginalAppointmentInfo.AppointmentEffectiveDate
			 and hi.[Effective Date] >= isnull((SELECT MAX(hi2.[Effective Date])
                                                   from #HistoricalAppointmentInfo hi2
		                                          Where hi2.[Original Appointment] = #OriginalAppointmentInfo.AppointmentOriginalAppointment
			                                        and hi2.FullTimeAnnualPensionableSalary <> #OriginalAppointmentInfo.AppointmentFullTimeAnnualPensionableSalary
			                                        and hi2.[Effective Date] < #OriginalAppointmentInfo.AppointmentEffectiveDate
			                                          ),hi.[Effective Date])),#OriginalAppointmentInfo.AppointmentEffectiveDate)




   UPDATE #OriginalAppointmentInfo set PensionableSalaryEffectiveFrom = null, LGSSPartTimeHours = '0.01'
   WHERE LGSSPartTimeHours = '0.00'      


   Update #OriginalAppointmentInfo 
   SET AppointmentPartTimeHoursEffectiveFrom = null
   where AppointmentPartTimeHoursEffectiveFrom = '1753-01-01'

   
   UPDATE #OriginalAppointmentInfo 
   SET DateJoinedLGPS = AppointmentDate
   where DateJoinedLGPS = '1753-01-01'

/* MSS update to cope with where DateJoinedLGPS is less than the date the School Joined the Scheme! */
   UPDATE oa  
   SET DateJoinedLGPS = cs.[EPM Payroll Effectivefrom Date]
   FROM #OriginalAppointmentInfo oa join  #Customer cs on oa.ApptCustNo = cs.[No_]
      where DateJoinedLGPS < cs.[EPM Payroll Effectivefrom Date]

-- Do not want to show Future Opt Outs
   Update #OriginalAppointmentInfo  SET AppointmentOptOutDate = null 
    where (AppointmentOptOutDate = '1753-01-01' or AppointmentOptOutDate > @PeriodEnd)

-- do not want to show future Resignations
   Update #OriginalAppointmentInfo  
   SET AppointmentResignationDate = null 
      ,AppointmentResignationReason = null
   where (AppointmentResignationDate = '1753-01-01' or AppointmentResignationDate > @PeriodEnd)


   -- Data Cleanup where HR have re-issued appointment and not blanked out resignation reason.
   Update #OriginalAppointmentInfo  
   SET AppointmentResignationReason = null
   where AppointmentResignationDate = null


   -- For Data Cleanup where Payroll have left an optout date in place.
   Update #OriginalAppointmentInfo set AppointmentOptOutDate = null where AppointmentOptOutDate < AppointmentEffectiveDate

   --MonthlySummary

   update  MS set ms.AnnualPensionableSalary = CASE WHEN ai.LGSSPartTimeHours = '0.01' THEN NULL-- No Annual Pensionable Salary
                                               ELSE
                                               CASE WHEN ai.AppointmentLGSSPTIndicator= 'Y' 
                                               THEN ai.AppointmentPartTimeAnnualPensionableSalary 
                                               ELSE ai.AppointmentFullTimeAnnualPensionableSalary
											   END
											   END
        											  

    FROM  #LGPSMonthlySummary ms join #OriginalAppointmentInfo ai on ms.PayDetailOriginalAppointmentNumber  = ai.AppointmentOriginalAppointment

/* Test output  */

Update #LGPSMonthlySummary 
set Pen8FTEAmount=null
where PayDetailOriginalAppointmentNumber in (select app.[Original Appointment]  
         from [EPM$Appointment] app where isNull(app.[Resignation Date],'1753-01-01') > @PEN8PeriodStart13 
		                                                         and isNull(app.[Resignation Date],'1753-01-01') <  @PeriodStart )

  Select * 
  -- into dbo.SSRS_OutputLGPS
  from #LGPSMonthlySummary  ms
       LEFT JOIN #OriginalAppointmentInfo ai on ms.PayDetailOriginalAppointmentNumber= ai.AppointmentOriginalAppointment	  
  END



