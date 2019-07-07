


CREATE PROCEDURE [dbo].[SSRS_PENSION_FUNDS_V2] (@Pensions Varchar(4)
                                       ,@TAXYEAR int 
                                       ,@PERIOD int 
                                       ,@DfES Varchar(10)
									   ,@School Varchar(10) 
									   ,@PensionCode Varchar(30)
									   ,@All Varchar(1)
									   ,@NewStarters varchar(1)
									   ,@Leavers varchar(1)
									   ,@changes varchar(1)
									   ,@Customertype varchar(100)
									   ,@OriginalAppointment Varchar(10) = null
									   ,@Template VarChar(255)-- = 'Norfolk Pension Fund - Joiners'
									   )

AS

	DECLARE @Period1 int	
	DECLARE @Period2 int
	IF @PERIOD = 0
		BEGIN
			SET @Period1 = 1
			SET @Period2 = 12
		END
	ELSE
		BEGIN
			SET @Period1 = @PERIOD
			SET @Period2 = @PERIOD
		END

	DECLARE  @PeriodStart Date = cast((Select  distinct FirstDayOfMonth from DimDate_SSRS dm where TaxYear = @TAXYEAR  and TaxPeriod = @Period1) as date)
	DECLARE  @PeriodEnd Date= cast((Select  distinct LastDayOfMonth from DimDate_SSRS dm where TaxYear = @TAXYEAR  and TaxPeriod = @Period2) as date)
	DECLARE  @PeriodEnd_1 Date = cast((Select distinct DATEADD(DD,-1,LastDayOfMonth) from DimDate_SSRS dm where TaxYear = @TAXYEAR and TaxPeriod = @PERIOD2 ) as date)
	DECLARE  @PreviousTaxPeriod int = cast((Select dm.TaxPeriod from DimDate_SSRS dm where DimDate = DATEADD(DAY,-1,@PeriodStart)) as int)
	DECLARE  @PreviousTaxYear int=  cast((Select dm.TaxPeriod  from DimDate_SSRS dm where DimDate = DATEADD(DAY,-1,@PeriodStart))  as int)   

	DECLARE  @PEN8PeriodStart Date
	DECLARE  @PEN8PeriodStart13 Date
	DECLARE  @PEN8PeriodEnd13 Date

	  SET @PEN8PeriodStart = DATEADD(DD,1,DATEADD(MM,-12,@PeriodEnd))
/* MSS Added below For 13th month issue of regignations mid-month - Needing to calculate the Pen8FTE Amount! */
	  SET @PEN8PeriodStart13 = DATEADD(DD,1,DATEADD(MM,-13,@PeriodEnd))
	  SET @PEN8PeriodEnd13 = DATEADD(DD,1,DATEADD(DD,-2,@PEN8PeriodStart))

	DECLARE  @Pen8_365Days decimal = (select count(dm.dimdate) from DimDate_SSRS dm where dm.dimdate between @PEN8PeriodStart and @PeriodEnd)
	DECLARE  @SQLString as NVarChar(4000)
	DECLARE @CURRENTPERIOD as int    /* to handle when period 0 to know which month is the latest */

	SET @SQLString =	(	
							SELECT N'SELECT ' + 
							case when Field01 = ', ''NOTINUSE'' Field01' then '''BLANK'' Field01' else Field01 + ' Field01' end + 
							case when Field02 is null then ', ''NOTINUSE'' Field02' when Field02 = '' then ', ''BLANK'' Field02' else ', ' + Field02 + ' Field02' end + 
							case when Field03 is null then ', ''NOTINUSE'' Field03' when Field03 = '' then ', ''BLANK'' Field03' else ', ' + Field03 + ' Field03' end + 
							case when Field04 is null then ', ''NOTINUSE'' Field04' when Field04 = '' then ', ''BLANK'' Field04' else ', ' + Field04 + ' Field04' end + 
							case when Field05 is null then ', ''NOTINUSE'' Field05' when Field05 = '' then ', ''BLANK'' Field05' else ', ' + Field05 + ' Field05' end + 
							case when Field06 is null then ', ''NOTINUSE'' Field06' when Field06 = '' then ', ''BLANK'' Field06' else ', ' + Field06 + ' Field06' end + 
							case when Field07 is null then ', ''NOTINUSE'' Field07' when Field07 = '' then ', ''BLANK'' Field07' else ', ' + Field07 + ' Field07' end + 
							case when Field08 is null then ', ''NOTINUSE'' Field08' when Field08 = '' then ', ''BLANK'' Field08' else ', ' + Field08 + ' Field08' end + 
							case when Field09 is null then ', ''NOTINUSE'' Field09' when Field09 = '' then ', ''BLANK'' Field09' else ', ' + Field09 + ' Field09' end + 
							case when Field10 is null then ', ''NOTINUSE'' Field10' when Field10 = '' then ', ''BLANK'' Field10' else ', ' + Field10 + ' Field10' end + 
							case when Field11 is null then ', ''NOTINUSE'' Field11' when Field11 = '' then ', ''BLANK'' Field11' else ', ' + Field11 + ' Field11' end + 
							case when Field12 is null then ', ''NOTINUSE'' Field12' when Field12 = '' then ', ''BLANK'' Field12' else ', ' + Field12 + ' Field12' end + 
							case when Field13 is null then ', ''NOTINUSE'' Field13' when Field13 = '' then ', ''BLANK'' Field13' else ', ' + Field13 + ' Field13' end + 
							case when Field14 is null then ', ''NOTINUSE'' Field14' when Field14 = '' then ', ''BLANK'' Field14' else ', ' + Field14 + ' Field14' end + 
							case when Field15 is null then ', ''NOTINUSE'' Field15' when Field15 = '' then ', ''BLANK'' Field15' else ', ' + Field15 + ' Field15' end + 
							case when Field16 is null then ', ''NOTINUSE'' Field16' when Field16 = '' then ', ''BLANK'' Field16' else ', ' + Field16 + ' Field16' end + 
							case when Field17 is null then ', ''NOTINUSE'' Field17' when Field17 = '' then ', ''BLANK'' Field17' else ', ' + Field17 + ' Field17' end + 
							case when Field18 is null then ', ''NOTINUSE'' Field18' when Field18 = '' then ', ''BLANK'' Field18' else ', ' + Field18 + ' Field18' end + 
							case when Field19 is null then ', ''NOTINUSE'' Field19' when Field19 = '' then ', ''BLANK'' Field19' else ', ' + Field19 + ' Field19' end + 
							case when Field20 is null then ', ''NOTINUSE'' Field20' when Field20 = '' then ', ''BLANK'' Field20' else ', ' + Field20 + ' Field20' end + 
							case when Field21 is null then ', ''NOTINUSE'' Field21' when Field21 = '' then ', ''BLANK'' Field21' else ', ' + Field21 + ' Field21' end + 
							case when Field22 is null then ', ''NOTINUSE'' Field22' when Field22 = '' then ', ''BLANK'' Field22' else ', ' + Field22 + ' Field22' end + 
							case when Field23 is null then ', ''NOTINUSE'' Field23' when Field23 = '' then ', ''BLANK'' Field23' else ', ' + Field23 + ' Field23' end + 
							case when Field24 is null then ', ''NOTINUSE'' Field24' when Field24 = '' then ', ''BLANK'' Field24' else ', ' + Field24 + ' Field24' end + 
							case when Field25 is null then ', ''NOTINUSE'' Field25' when Field25 = '' then ', ''BLANK'' Field25' else ', ' + Field25 + ' Field25' end + 
							case when Field26 is null then ', ''NOTINUSE'' Field26' when Field26 = '' then ', ''BLANK'' Field26' else ', ' + Field26 + ' Field26' end + 
							case when Field27 is null then ', ''NOTINUSE'' Field27' when Field27 = '' then ', ''BLANK'' Field27' else ', ' + Field27 + ' Field27' end + 
							case when Field28 is null then ', ''NOTINUSE'' Field28' when Field28 = '' then ', ''BLANK'' Field28' else ', ' + Field28 + ' Field28' end + 
							case when Field29 is null then ', ''NOTINUSE'' Field29' when Field29 = '' then ', ''BLANK'' Field29' else ', ' + Field29 + ' Field29' end + 
							case when Field30 is null then ', ''NOTINUSE'' Field30' when Field30 = '' then ', ''BLANK'' Field30' else ', ' + Field30 + ' Field30' end + 
							case when Field31 is null then ', ''NOTINUSE'' Field31' when Field31 = '' then ', ''BLANK'' Field31' else ', ' + Field31 + ' Field31' end + 
							case when Field32 is null then ', ''NOTINUSE'' Field32' when Field32 = '' then ', ''BLANK'' Field32' else ', ' + Field32 + ' Field32' end + 
							case when Field33 is null then ', ''NOTINUSE'' Field33' when Field33 = '' then ', ''BLANK'' Field33' else ', ' + Field33 + ' Field33' end + 
							case when Field34 is null then ', ''NOTINUSE'' Field34' when Field34 = '' then ', ''BLANK'' Field34' else ', ' + Field34 + ' Field34' end + 
							case when Field35 is null then ', ''NOTINUSE'' Field35' when Field35 = '' then ', ''BLANK'' Field35' else ', ' + Field35 + ' Field35' end + 
							case when Field36 is null then ', ''NOTINUSE'' Field36' when Field36 = '' then ', ''BLANK'' Field36' else ', ' + Field36 + ' Field36' end + 
							case when Field37 is null then ', ''NOTINUSE'' Field37' when Field37 = '' then ', ''BLANK'' Field37' else ', ' + Field37 + ' Field37' end + 
							case when Field38 is null then ', ''NOTINUSE'' Field38' when Field38 = '' then ', ''BLANK'' Field38' else ', ' + Field38 + ' Field38' end + 
							case when Field39 is null then ', ''NOTINUSE'' Field39' when Field39 = '' then ', ''BLANK'' Field39' else ', ' + Field39 + ' Field39' end + 
							case when Field40 is null then ', ''NOTINUSE'' Field40' when Field40 = '' then ', ''BLANK'' Field40' else ', ' + Field40 + ' Field40' end + 
							case when Field41 is null then ', ''NOTINUSE'' Field41' when Field41 = '' then ', ''BLANK'' Field41' else ', ' + Field41 + ' Field41' end + 
							case when Field42 is null then ', ''NOTINUSE'' Field42' when Field42 = '' then ', ''BLANK'' Field42' else ', ' + Field42 + ' Field42' end + 
							case when Field43 is null then ', ''NOTINUSE'' Field43' when Field43 = '' then ', ''BLANK'' Field43' else ', ' + Field43 + ' Field43' end + 
							case when Field44 is null then ', ''NOTINUSE'' Field44' when Field44 = '' then ', ''BLANK'' Field44' else ', ' + Field44 + ' Field44' end + 
							case when Field45 is null then ', ''NOTINUSE'' Field45' when Field45 = '' then ', ''BLANK'' Field45' else ', ' + Field45 + ' Field45' end + 
							case when Field46 is null then ', ''NOTINUSE'' Field46' when Field46 = '' then ', ''BLANK'' Field46' else ', ' + Field46 + ' Field46' end + 
							case when Field47 is null then ', ''NOTINUSE'' Field47' when Field47 = '' then ', ''BLANK'' Field47' else ', ' + Field47 + ' Field47' end + 
							case when Field48 is null then ', ''NOTINUSE'' Field48' when Field48 = '' then ', ''BLANK'' Field48' else ', ' + Field48 + ' Field48' end + 
							case when Field49 is null then ', ''NOTINUSE'' Field49' when Field49 = '' then ', ''BLANK'' Field49' else ', ' + Field49 + ' Field49' end + 
							case when Field50 is null then ', ''NOTINUSE'' Field50' when Field50 = '' then ', ''BLANK'' Field50' else ', ' + Field50 + ' Field50' end + 
							case when Field51 is null then ', ''NOTINUSE'' Field51' when Field51 = '' then ', ''BLANK'' Field51' else ', ' + Field51 + ' Field51' end + 
							case when Field52 is null then ', ''NOTINUSE'' Field52' when Field52 = '' then ', ''BLANK'' Field52' else ', ' + Field52 + ' Field52' end + 
							case when Field53 is null then ', ''NOTINUSE'' Field53' when Field53 = '' then ', ''BLANK'' Field53' else ', ' + Field53 + ' Field53' end + 
							case when Field54 is null then ', ''NOTINUSE'' Field54' when Field54 = '' then ', ''BLANK'' Field54' else ', ' + Field54 + ' Field54' end + 
							case when Field55 is null then ', ''NOTINUSE'' Field55' when Field55 = '' then ', ''BLANK'' Field55' else ', ' + Field55 + ' Field55' end + 
							case when Field56 is null then ', ''NOTINUSE'' Field56' when Field56 = '' then ', ''BLANK'' Field56' else ', ' + Field56 + ' Field56' end + 
							case when Field57 is null then ', ''NOTINUSE'' Field57' when Field57 = '' then ', ''BLANK'' Field57' else ', ' + Field57 + ' Field57' end + 
							case when Field58 is null then ', ''NOTINUSE'' Field58' when Field58 = '' then ', ''BLANK'' Field58' else ', ' + Field58 + ' Field58' end + 
							case when Field59 is null then ', ''NOTINUSE'' Field59' when Field59 = '' then ', ''BLANK'' Field59' else ', ' + Field59 + ' Field59' end + 
							case when Field60 is null then ', ''NOTINUSE'' Field60' when Field60 = '' then ', ''BLANK'' Field60' else ', ' + Field60 + ' Field60' end + 
							case when Field61 is null then ', ''NOTINUSE'' Field61' when Field61 = '' then ', ''BLANK'' Field61' else ', ' + Field61 + ' Field61' end + 
							case when Field62 is null then ', ''NOTINUSE'' Field62' when Field62 = '' then ', ''BLANK'' Field62' else ', ' + Field62 + ' Field62' end + 
							case when Field63 is null then ', ''NOTINUSE'' Field63' when Field63 = '' then ', ''BLANK'' Field63' else ', ' + Field63 + ' Field63' end + 
							case when Field64 is null then ', ''NOTINUSE'' Field64' when Field64 = '' then ', ''BLANK'' Field64' else ', ' + Field64 + ' Field64' end + 
							case when Field65 is null then ', ''NOTINUSE'' Field65' when Field65 = '' then ', ''BLANK'' Field65' else ', ' + Field65 + ' Field65' end + 
							case when Field66 is null then ', ''NOTINUSE'' Field66' when Field66 = '' then ', ''BLANK'' Field66' else ', ' + Field66 + ' Field66' end + 
							case when Field67 is null then ', ''NOTINUSE'' Field67' when Field67 = '' then ', ''BLANK'' Field67' else ', ' + Field67 + ' Field67' end + 
							case when Field68 is null then ', ''NOTINUSE'' Field68' when Field68 = '' then ', ''BLANK'' Field68' else ', ' + Field68 + ' Field68' end + 
							case when Field69 is null then ', ''NOTINUSE'' Field69' when Field69 = '' then ', ''BLANK'' Field69' else ', ' + Field69 + ' Field69' end + 
							case when Field70 is null then ', ''NOTINUSE'' Field70' when Field70 = '' then ', ''BLANK'' Field70' else ', ' + Field70 + ' Field70' end + 
							case when Field71 is null then ', ''NOTINUSE'' Field71' when Field71 = '' then ', ''BLANK'' Field71' else ', ' + Field71 + ' Field71' end + 
							case when Field72 is null then ', ''NOTINUSE'' Field72' when Field72 = '' then ', ''BLANK'' Field72' else ', ' + Field72 + ' Field72' end + 
							case when Field73 is null then ', ''NOTINUSE'' Field73' when Field73 = '' then ', ''BLANK'' Field73' else ', ' + Field73 + ' Field73' end + 
							case when Field74 is null then ', ''NOTINUSE'' Field74' when Field74 = '' then ', ''BLANK'' Field74' else ', ' + Field74 + ' Field74' end + 
							case when Field75 is null then ', ''NOTINUSE'' Field75' when Field75 = '' then ', ''BLANK'' Field75' else ', ' + Field75 + ' Field75' end + 
							' ' + 
							'FROM #LGPSMonthlySummary  ms
								LEFT JOIN #OriginalAppointmentInfo ai on ms.PayDetailOriginalAppointmentNumber= ai.AppointmentOriginalAppointment
								' + ISNULL(Logic, '') +
								' GROUP BY ' +
								case when Field01 = '' then '' else Field01 + ' ' end + 
							case when Field02 is null then '' when Field02 = '' then '' else ', ' + Field02 + '' end + 
							case when Field03 is null then '' when Field03 = '' then '' else ', ' + Field03 + '' end + 
							case when Field04 is null then '' when Field04 = '' then '' else ', ' + Field04 + '' end + 
							case when Field05 is null then '' when Field05 = '' then '' else ', ' + Field05 + '' end + 
							case when Field06 is null then '' when Field06 = '' then '' else ', ' + Field06 + '' end + 
							case when Field07 is null then '' when Field07 = '' then '' else ', ' + Field07 + '' end + 
							case when Field08 is null then '' when Field08 = '' then '' else ', ' + Field08 + '' end + 
							case when Field09 is null then '' when Field09 = '' then '' else ', ' + Field09 + '' end + 
							case when Field10 is null then '' when Field10 = '' then '' else ', ' + Field10 + '' end + 
							case when Field11 is null then '' when Field11 = '' then '' else ', ' + Field11 + '' end + 
							case when Field12 is null then '' when Field12 = '' then '' else ', ' + Field12 + '' end + 
							case when Field13 is null then '' when Field13 = '' then '' else ', ' + Field13 + '' end + 
							case when Field14 is null then '' when Field14 = '' then '' else ', ' + Field14 + '' end + 
							case when Field15 is null then '' when Field15 = '' then '' else ', ' + Field15 + '' end + 
							case when Field16 is null then '' when Field16 = '' then '' else ', ' + Field16 + '' end + 
							case when Field17 is null then '' when Field17 = '' then '' else ', ' + Field17 + '' end + 
							case when Field18 is null then '' when Field18 = '' then '' else ', ' + Field18 + '' end + 
							case when Field19 is null then '' when Field19 = '' then '' else ', ' + Field19 + '' end + 
							case when Field20 is null then '' when Field20 = '' then '' else ', ' + Field20 + '' end + 
							case when Field21 is null then '' when Field21 = '' then '' else ', ' + Field21 + '' end + 
							case when Field22 is null then '' when Field22 = '' then '' else ', ' + Field22 + '' end + 
							case when Field23 is null then '' when Field23 = '' then '' else ', ' + Field23 + '' end + 
							case when Field24 is null then '' when Field24 = '' then '' else ', ' + Field24 + '' end + 
							case when Field25 is null then '' when Field25 = '' then '' else ', ' + Field25 + '' end + 
							case when Field26 is null then '' when Field26 = '' then '' else ', ' + Field26 + '' end + 
							case when Field27 is null then '' when Field27 = '' then '' else ', ' + Field27 + '' end + 
							case when Field28 is null then '' when Field28 = '' then '' else ', ' + Field28 + '' end + 
							case when Field29 is null then '' when Field29 = '' then '' else ', ' + Field29 + '' end + 
							case when Field30 is null then '' when Field30 = '' then '' else ', ' + Field30 + '' end + 
							case when Field31 is null then '' when Field31 = '' then '' else ', ' + Field31 + '' end + 
							case when Field32 is null then '' when Field32 = '' then '' else ', ' + Field32 + '' end + 
							case when Field33 is null then '' when Field33 = '' then '' else ', ' + Field33 + '' end + 
							case when Field34 is null then '' when Field34 = '' then '' else ', ' + Field34 + '' end + 
							case when Field35 is null then '' when Field35 = '' then '' else ', ' + Field35 + '' end + 
							case when Field36 is null then '' when Field36 = '' then '' else ', ' + Field36 + '' end + 
							case when Field37 is null then '' when Field37 = '' then '' else ', ' + Field37 + '' end + 
							case when Field38 is null then '' when Field38 = '' then '' else ', ' + Field38 + '' end + 
							case when Field39 is null then '' when Field39 = '' then '' else ', ' + Field39 + '' end + 
							case when Field40 is null then '' when Field40 = '' then '' else ', ' + Field40 + '' end + 
							case when Field41 is null then '' when Field41 = '' then '' else ', ' + Field41 + '' end + 
							case when Field42 is null then '' when Field42 = '' then '' else ', ' + Field42 + '' end + 
							case when Field43 is null then '' when Field43 = '' then '' else ', ' + Field43 + '' end + 
							case when Field44 is null then '' when Field44 = '' then '' else ', ' + Field44 + '' end + 
							case when Field45 is null then '' when Field45 = '' then '' else ', ' + Field45 + '' end + 
							case when Field46 is null then '' when Field46 = '' then '' else ', ' + Field46 + '' end + 
							case when Field47 is null then '' when Field47 = '' then '' else ', ' + Field47 + '' end + 
							case when Field48 is null then '' when Field48 = '' then '' else ', ' + Field48 + '' end + 
							case when Field49 is null then '' when Field49 = '' then '' else ', ' + Field49 + '' end + 
							case when Field50 is null then '' when Field50 = '' then '' else ', ' + Field50 + '' end + 
							case when Field51 is null then '' when Field51 = '' then '' else ', ' + Field51 + '' end + 
							case when Field52 is null then '' when Field52 = '' then '' else ', ' + Field52 + '' end + 
							case when Field53 is null then '' when Field53 = '' then '' else ', ' + Field53 + '' end + 
							case when Field54 is null then '' when Field54 = '' then '' else ', ' + Field54 + '' end + 
							case when Field55 is null then '' when Field55 = '' then '' else ', ' + Field55 + '' end + 
							case when Field56 is null then '' when Field56 = '' then '' else ', ' + Field56 + '' end + 
							case when Field57 is null then '' when Field57 = '' then '' else ', ' + Field57 + '' end + 
							case when Field58 is null then '' when Field58 = '' then '' else ', ' + Field58 + '' end + 
							case when Field59 is null then '' when Field59 = '' then '' else ', ' + Field59 + '' end + 
							case when Field60 is null then '' when Field60 = '' then '' else ', ' + Field60 + '' end + 
							case when Field61 is null then '' when Field61 = '' then '' else ', ' + Field61 + '' end + 
							case when Field62 is null then '' when Field62 = '' then '' else ', ' + Field62 + '' end + 
							case when Field63 is null then '' when Field63 = '' then '' else ', ' + Field63 + '' end + 
							case when Field64 is null then '' when Field64 = '' then '' else ', ' + Field64 + '' end + 
							case when Field65 is null then '' when Field65 = '' then '' else ', ' + Field65 + '' end + 
							case when Field66 is null then '' when Field66 = '' then '' else ', ' + Field66 + '' end + 
							case when Field67 is null then '' when Field67 = '' then '' else ', ' + Field67 + '' end + 
							case when Field68 is null then '' when Field68 = '' then '' else ', ' + Field68 + '' end + 
							case when Field69 is null then '' when Field69 = '' then '' else ', ' + Field69 + '' end + 
							case when Field70 is null then '' when Field70 = '' then '' else ', ' + Field70 + '' end + 
							case when Field71 is null then '' when Field71 = '' then '' else ', ' + Field71 + '' end + 
							case when Field72 is null then '' when Field72 = '' then '' else ', ' + Field72 + '' end + 
							case when Field73 is null then '' when Field73 = '' then '' else ', ' + Field73 + '' end + 
							case when Field74 is null then '' when Field74 = '' then '' else ', ' + Field74 + '' end + 
							case when Field75 is null then '' when Field75 = '' then '' else ', ' + Field75 + '' end 
							FROM [EPMv6].dbo.Filters 
							WHERE Name = @Template
						)

		--set @School = isnull(@School,'')
		--set @DfES   = isnull(@dfes,'') 
		--set @PensionCode = isnull(@PensionCode,'')
	
		set @Customertype = isnull(@CustomerType,'')

	--	IF OBJECT_ID('tempdb..#LGPSDATA') IS NOT NULL DROP TABLE #LGPSDATA
		IF OBJECT_ID('tempdb..#LGPSMonthlySummary') IS NOT NULL DROP TABLE #LGPSMonthlySummary
		IF OBJECT_ID('tempdb..#PensionType') IS NOT NULL DROP TABLE #PensionType
		IF OBJECT_ID('tempdb..#LGPSYTD') IS NOT NULL DROP TABLE #LGPSYTD
		IF OBJECT_ID('tempdb..#LGPSPayrollEmployee') IS NOT NULL DROP TABLE #LGPSPayrollEmployee
		IF OBJECT_ID('tempdb..#Customer') IS NOT NULL DROP TABLE #Customer
		IF OBJECT_ID('tempdb..#PEN8_DATA_LOCAL') IS NOT NULL DROP TABLE #PEN8_DATA_LOCAL
		IF OBJECT_ID('tempdb..#HREmp') IS NOT NULL DROP TABLE #HREmp
        IF OBJECT_ID('tempdb..#Periods') IS NOT NULL DROP TABLE #Periods
        IF OBJECT_ID('tempdb..#Period13') IS NOT NULL DROP TABLE #Period13
        IF OBJECT_ID('tempdb..#Pen8AppointmentInfo') IS NOT NULL DROP TABLE #Pen8AppointmentInfo
        IF OBJECT_ID('tempdb..#OriginalAppointmentInfo') IS NOT NULL DROP TABLE #OriginalAppointmentInfo
        IF OBJECT_ID('tempdb..#HistoricalAppointmentInfo') IS NOT NULL DROP TABLE #HistoricalAppointmentInfo
        IF OBJECT_ID('tempdb..#HoursEffectiveFrom') IS NOT NULL DROP TABLE #HoursEffectiveFrom



		SELECT DISTINCT pen.[pension type]   
		  into #PensionType
		  FROM  [EPM$Pension Scheme]   PEN with(nolock)
		  WHERE ( @Pensions = 'LGPS' and  pen.[pension type]   in (3,4) or @PEnsions = 'TPS' and pen.[pension type]   in (3,4))

		 
       Select distinct CASE WHEN @PEN8PeriodStart BETWEEN dm.FirstDayOfMonth and dm.LastDayOfMonth then @PEN8PeriodStart else dm.FirstDayOfMonth END as 'AppointmentFirstDayOfMonth'
                      ,case WHEN @PeriodEnd        BETWEEN dm.FirstDayOfMonth and dm.LastDayOfMonth then @PeriodEnd       else dm.LastDayOfMonth  END as 'AppointmentLastDayOfMonth'
					  ,dm.LastDayOfMonth  as 'LastDayOfMonth'
			          ,dm.TaxPeriod
			          ,dm.TaxYear
			          ,cast(count(dm.dimdate) as decimal(10,6)) as 'DaysInPeriod'
			          ,cast((Select count(dm2.MonthYear) from DimDate_SSRS dm2  where dm2.MonthYear= dm.MonthYear) as decimal(10,6)) AS 'DaysInMonth'
                into #Periods
                from DimDate_SSRS dm with(nolock)
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
	 from [EPM$Customer] cs with(nolock)
	 WHERE cs.[DfES Area] = ISNULL(@DfES,cs.[DfES Area])
	  and cs.No_ = isnull(@School,cs.No_ ) 
	  and (cs.[Employer Pension Code] = ISNULL(@PensionCode,cs.[Employer Pension Code])  or cs.[LGPS Pension Fund] = isnull(@PensionCode,cs.[LGPS Pension Fund] ) )
	  and cs.[Payroll Provider] = 'EPM'
	  and ( cs.[EPM Payroll End Date] = '1753-01-01' or cs.[EPM Payroll End Date]  >  @PeriodStart)

-- Main query

select *, '' LGSS_FILE_REF INTO #LGPSMonthlySummary FROM (
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
		,CUS.[DfES Area] DfES_Area
        ,CUS.[Employer Pension Code] As 'CustomerEmployerPensionCode'
        ,cus.[School DfES No_]       as 'CustomerSchoolDfESAlpha'
        ,replace(cus.[School DfES No_],'/','') as 'CustomerSchoolDfESNumber'
        ,cus.[PAYROLL REF]                     as 'CustomerPayrollRef'
        ,cast(CUS.Name   as varchar(40) )      as 'CustomerName'
        ,CUS.[Customer Type]                   as 'CustomerType'
        ,CUS.[Employer Code]                   as 'CustomerEmployerCode'
		,app.[Budget Code 1]					as 'AppointmentBudgetCode'
		,app.[LGPS Membership No_]				as 'AppointmentLGPSMembershipNumber'
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



		,max(CASE WHEN pen.[pension type] in (1,3) and pen.[type] = 0 THEN CONVERT(decimal(18,2), [Ee Pens_ Contr_ %]) ELSE 0 END ) as 'EmployeePensionPercentage'

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
			  END ) as decimal(10,2)) as 'Period50_50EmployeeAmount'

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
			  END )  as decimal(10,2)) as 'Period50_50EmployerAmount'

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
			        
		,cast(sum(CASE WHEN ISNULL(pdl.Description, '') = 'LGPS Office'
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
          cast(000.00 as decimal(16,2))  as 'ID5050PensionablePayYTD',
          cast(000.00 as decimal(16,2))  as 'ID5050EmployerContributionYTD',
          cast(000.00 as decimal(16,2))  as 'ID5050EmployeeContributionYTD',
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
		  cast(000.00 as Decimal(16,2))  as 'AnnualisedPen8FTEAmount',
		  cast(000.00 as Decimal(16,2))  as 'Pen8WeeksWorkedAmount',
		  cast(000.00 as Decimal(16,2))  as 'EmployerTotalPensionAmountYTD',
		  'Y'                            as 'PeriodEmployeePensionTotalsOK',
		  'Y'                            as 'PeriodEmployerPensionTotalsOK',
		  'Y'                            as 'YTDEmployeePensionTotalsOK',
		  'Y'                            as 'YTDEmployerPensionTotalsOK'
	/*
    From  #Customer cs
	      INNER JOIN [EPM$Customer] cus ON cs.no_ = cus.No_
		  INNER JOIN [EPM$Pay Detail Line] Pdl ON pdl.[Payroll Group Code] = cus.No_
	      INNER JOIN [EPM$Pension Scheme]   PEN  ON PDL.[Reference] = PEN.[Scheme No_]and   (pen.[Pension Type] in (1,2) and @Pensions = 'TPS' or  pen.[Pension Type] in (3,4) and @Pensions = 'LGPS')
		  INNER JOIN [EPM$Payroll Employee] pem on PDL.[Employee No_] = pem.No_ and pdl.[Payroll Group Code] = pem.[Payroll Group Code]
		  INNER JOIN #HREmp emp on pem.[HR Employee No_] = emp.No_ and cus.No_ = emp.[School No_]
	where cs.no_ = cus.No_
	  and pdl.[Payroll Group Code] = cus.No_ 
	  and pdl.[Pay Element Code] = 'PENSION'
	  and (pdl.[Tax Year] = @TAXYEAR and pdl.Period = @PERIOD)
	  and pdl.Amount <> 0 and cus.no_ = emp.[School No_]
	  */
	FROM
	#Customer cs
	left outer join [EPM$Customer] CUS with(nolock) ON cs.no_ = cus.No_
	left outer join [EPM$School Employee] emp with(nolock) ON cus.No_ = emp.[School No_]
	left outer join [EPM$Payroll Employee] PEM with(nolock) ON cus.No_ = pem.[Payroll Group Code] and LEFT(emp.No_, 7) = LEFT(pem.No_, 7)
	left outer join [EPM$Pay Detail Line] PDL with(nolock) ON LEFT(PEM.[No_], 7) = LEFT(pdl.[Employee No_], 7) and pem.[Payroll Group Code] = pdl.[Payroll Group Code]
	left outer join [EPM$Appointment] APP with(nolock) ON pdl.[Appointment No_] = app.No_ and pdl.[Payroll Group Code] = app.[Customer No_]
    left outer join [EPM$Pay Element] pe1 with(nolock) on app.[Allowance Code 1] = pe1.code and pe1.Pension = 1
	left outer join [EPM$Pay Element] pe2 with(nolock) on app.[Allowance Code 2] = pe2.code and pe2.Pension = 1
	left outer join [EPM$Pay Element] pe3 with(nolock) on app.[Allowance Code 3] = pe3.code and pe3.Pension = 1
	left outer join [EPM$Pay Element] pe4 with(nolock) on app.[Allowance Code 4] = pe4.code and pe4.NI = 1
	left outer join [EPM$Pension Scheme] PEN with(nolock)  ON UPPER(pdl.reference )  = UPPER(PEN.[Scheme No_])
	WHERE   
    (@TAXYEAR = pdl.[Tax Year] and ((@PERIOD = pdl.Period) OR @PERIOD=0))
	and pdl.[Pay Element Code] = 'PENSION'   
	and (
	app.[Pension 1] like  @Pensions+'%'    or app.[Pension 1] like  '%'+@Pensions  or (app.[Opted out of LGPS] between @PeriodStart and @PeriodEnd)
    or (pdl.[Pension 1] = '' and pdl.[Pension 2] = '' and pdl.Description like  @Pensions+'%')
	or (pen.[Pension Type] in (1,2) and @Pensions = 'TPS' or  pen.[Pension Type] in (3,4) and @Pensions = 'LGPS')
	)
	AND PDL.Amount <> '0'
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
			  ,app.[Budget Code 1]
			  ,app.[LGPS Membership No_]
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
		,CUS.[DfES Area] DfES_Area
        ,CUS.[Employer Pension Code] As 'CustomerEmployerPensionCode'
        ,cus.[School DfES No_]       as 'CustomerSchoolDfESAlpha'
        ,replace(cus.[School DfES No_],'/','') as 'CustomerSchoolDfESNumber'
        ,cus.[PAYROLL REF]                     as 'CustomerPayrollRef'
        ,cast(CUS.Name   as varchar(40) )      as 'CustomerName'
        ,CUS.[Customer Type]                   as 'CustomerType'
        ,CUS.[Employer Code]                   as 'CustomerEmployerCode'
		,app.[Budget Code 1]				   as 'AppointmentBudgetCode'
		,app.[LGPS Membership No_]				as 'AppointmentLGPSMembershipNumber'
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



		,max(CASE WHEN pen.[pension type] in (1,3) and pen.[type] = 0 THEN CONVERT(decimal(18,2), [Ee Pens_ Contr_ %]) ELSE 0 END ) as 'EmployeePensionPercentage'

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
			  END ) as decimal(10,2)) as 'Period50_50EmployeeAmount'

        ,cast(sum(CASE WHEN pen.[Pension Type] in (2,4)
              and pen.[50_50 Scheme] = 0 
			  and pen.[Added Years]  = 1 
			  THEN pdl.amount 
			  ELSE 0 
			  END ) as decimal(10,2)) as 'PeriodEmployeeAddedYearsAmount'



        ,cast(sum(CASE WHEN pen.[Pension Type] not in (2,4) --and pen.[type] in (2,3) --AVC
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
			  END )as decimal(10,2)) as 'Period50_50EmployerAmount'

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
			        
		,cast(sum(CASE WHEN ISNULL(pdl.Description, '') = 'LGPS Office'
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
          cast(000.00 as decimal(16,2))  as 'ID5050PensionablePayYTD',
          cast(000.00 as decimal(16,2))  as 'ID5050EmployerContributionYTD',
          cast(000.00 as decimal(16,2))  as 'ID5050EmployeeContributionYTD',
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
		  cast(000.00 as Decimal(16,2))  as 'AnnualisedPen8FTEAmount',
		  cast(000.00 as Decimal(16,2))  as 'Pen8WeeksWorkedAmount',
		  cast(000.00 as Decimal(16,2))  as 'EmployerTotalPensionAmountYTD',
		  'Y'                            as 'PeriodEmployeePensionTotalsOK',
		  'Y'                            as 'PeriodEmployerPensionTotalsOK',
		  'Y'                            as 'YTDEmployeePensionTotalsOK',
		  'Y'                            as 'YTDEmployerPensionTotalsOK'
    /*
	From  #Customer cs
	      INNER JOIN [EPM$Customer] cus ON cs.no_ = cus.No_
		  INNER JOIN [EPM$Pay Detail Line] Pdl ON pdl.[Payroll Group Code] = cus.No_
	      INNER JOIN [EPM$Pension Scheme]   PEN  ON PDL.[Reference] = PEN.[Scheme No_]and   (pen.[Pension Type] in (1,2) and @Pensions = 'TPS' or  pen.[Pension Type] in (3,4) and @Pensions = 'LGPS')
		  INNER JOIN [EPM$Payroll Archive] pem on PDL.[Employee No_] = pem.No_ and pdl.[Payroll Group Code] = pem.[Payroll Group Code]
		  INNER JOIN #HREmp emp on pem.No_ = emp.No_ and cus.No_ = emp.[School No_]
	where cs.no_ = cus.No_
	  and pdl.[Payroll Group Code] = cus.No_  and pdl.[Employee No_] = emp.No_
	  and pdl.[Pay Element Code] = 'PENSION'
	  and (pdl.[Tax Year] = @TAXYEAR and pdl.Period = @PERIOD)
	  and pdl.Amount <> 0 and cus.no_ = emp.[School No_]
	  */
	FROM
	#Customer cs
	left outer join [EPM$Customer] CUS with(nolock) ON cs.no_ = cus.No_
	left outer join [EPM$School Employee] emp with(nolock) ON cus.No_ = emp.[School No_]
	left outer join [EPM$Payroll Archive] PEM with(nolock) ON cus.No_ = pem.[Payroll Group Code] and LEFT(emp.No_, 7) = LEFT(pem.No_, 7)
	left outer join [EPM$Pay Detail Line] PDL with(nolock) ON LEFT(PEM.[No_], 7) = LEFT(pdl.[Employee No_], 7) and pem.[Payroll Group Code] = pdl.[Payroll Group Code]
	left outer join [EPM$Appointment] APP with(nolock) ON pdl.[Appointment No_] = app.No_ and pdl.[Payroll Group Code] = app.[Customer No_]
    left outer join [EPM$Pay Element] pe1 with(nolock) on app.[Allowance Code 1] = pe1.code and pe1.Pension = 1
	left outer join [EPM$Pay Element] pe2 with(nolock) on app.[Allowance Code 2] = pe2.code and pe2.Pension = 1
	left outer join [EPM$Pay Element] pe3 with(nolock) on app.[Allowance Code 3] = pe3.code and pe3.Pension = 1
	left outer join [EPM$Pay Element] pe4 with(nolock) on app.[Allowance Code 4] = pe4.code and pe4.NI = 1
	left outer join [EPM$Pension Scheme]   PEN with(nolock) ON UPPER(pdl.reference )  = UPPER(PEN.[Scheme No_])
	WHERE   
    (@TAXYEAR = pdl.[Tax Year] and ( (@PERIOD = pdl.Period) OR (@PERIOD=0) ))
	and pdl.[Pay Element Code] = 'PENSION'   
	and (
	app.[Pension 1] like  @Pensions+'%'    or app.[Pension 1] like  '%'+@Pensions  or (app.[Opted out of LGPS] between @PeriodStart and @PeriodEnd)
    or (pdl.[Pension 1] = '' and pdl.[Pension 2] = '' and pdl.Description like  @Pensions+'%')
	or (pen.[Pension Type] in (1,2) and @Pensions = 'TPS' or  pen.[Pension Type] in (3,4) and @Pensions = 'LGPS')
	)
	AND PDL.Amount <> '0'
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
			  ,app.[Budget Code 1]
			  ,app.[LGPS Membership No_]
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


        ,cast(sum(CASE WHEN pen.[Pension Type] not in (2,4) --and pen.[type] in (2,3) --AVC
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
		--	  , lg.EmployeePensionPercentage as 'EEPenPercentage' -- Added MSS 29Jan19 Didn't resolve the two percentage issue so removed


    INTO #LGPSYTD
      From #LGPSMonthlySummary lg,
	      #Customer cus,  
		 [EPM$Pay Detail Line] Pdl with(nolock)
         INNER JOIN [EPM$Pension Scheme]   PEN with(nolock) ON PDL.[Reference] = PEN.[Scheme No_]and   (pen.[Pension Type] in (1,2) and @Pensions = 'TPS' or  pen.[Pension Type] in (3,4) and  @Pensions= 'LGPS')
	where  cus.no_ = lg.PayDetailPayrollGroupCode
	  and pdl.[Payroll Group Code] = cus.no_
	  and pdl.[Pay Element Code] = 'PENSION'
	  and pdl.[Tax Year] = @TAXYEAR 
	  and ( (pdl.Period <= @PERIOD) OR (@PERIOD=0) )
	  and pdl.[Original Appointment No_] = lg.[PayDetailOriginalAppointmentNumber]
	  Group by pdl.[Payroll Group Code],
	                pdl.[Original Appointment No_]
--					,lg.EmployeePensionPercentage


-- Build the PEN8 Figures

 -- Build the PEN8 Figures
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
         [EPM$Appointment] app with(nolock)
     LEFT JOIN [EPM$Pay Element]pe1 with(nolock) on app.[Allowance Code 1] = pe1.code and pe1.Pension = 1
	 LEFT JOIN [EPM$Pay Element]pe2 with(nolock) on app.[Allowance Code 2] = pe2.code and pe2.Pension = 1
	 LEFT JOIN [EPM$Pay Element]pe3 with(nolock) on app.[Allowance Code 3] = pe3.code and pe3.Pension = 1
	 LEFT JOIN [EPM$Pay Element]pe4 with(nolock) on app.[Allowance Code 4] = pe4.code and pe4.NI = 1    
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

 --Select * from #PEN8_DATA_LOCAL

  
          UPDATE #LGPSMonthlySummary
		 SET #LGPSMonthlySummary.Pen8FTEAmount = #PEN8_DATA_LOCAL.TempPEN8Amount
                ,#LGPSMonthlySummary.AnnualisedPen8FTEAmount = #PEN8_DATA_LOCAL.AnnualisedPen8Amount
                ,#LGPSMonthlySummary.Pen8WeeksWorkedAmount = #PEN8_DATA_LOCAL.AnnualisedPen8WeeksWorkedAmount
           FROM #LGPSMonthlySummary INNER JOIN #PEN8_DATA_LOCAL ON #LGPSMonthlySummary.PayDetailOriginalAppointmentNumber= #PEN8_DATA_LOCAL.[Original Appointment]     


 IF @PERIOD = 0 
  BEGIN
 --    SET @CURRENTPERIOD = (select max(PayDetaillinePeriod) from #LGPSMonthlySummary)

         UPDATE #LGPSMonthlySummary 
            SET MainEmployeeContributionsYTD      = ytd.YTDEmployeeAmount/ (select count(1) from #LGPSMonthlySummary tms where tms.PayDetailOriginalAppointmentNumber = ms.PayDetailOriginalAppointmentNumber)
		       ,MainEmployerContributionsYTD          = ytd.YTDEmployerAmount/(select count(1) from #LGPSMonthlySummary tms where tms.PayDetailOriginalAppointmentNumber = ms.PayDetailOriginalAppointmentNumber)
			   ,EmployerTotalPensionAmountYTD      = ytd.YTDEmployerTotalPensionAmount/(select count(1) from #LGPSMonthlySummary tms where tms.PayDetailOriginalAppointmentNumber = ms.PayDetailOriginalAppointmentNumber)
	           ,[ID5050EmployeeContributionYTD]         = ytd.[YTD5050EmployeeAmount]/(select count(1) from #LGPSMonthlySummary tms where tms.PayDetailOriginalAppointmentNumber = ms.PayDetailOriginalAppointmentNumber)
		       ,[ID5050EmployerContributionYTD]          = ytd.[YTD5050EmployerAmount]/(select count(1) from #LGPSMonthlySummary tms where tms.PayDetailOriginalAppointmentNumber = ms.PayDetailOriginalAppointmentNumber)
		       ,EmployeeAddedYearsYTD                  = ytd.YTDEmployeeAddedYearsAmount/(select count(1) from #LGPSMonthlySummary tms where tms.PayDetailOriginalAppointmentNumber = ms.PayDetailOriginalAppointmentNumber)
		       ,EmployerAddedYearsYTD                   = ytd.YTDEmployerAddedYearsAmount/(select count(1) from #LGPSMonthlySummary tms where tms.PayDetailOriginalAppointmentNumber = ms.PayDetailOriginalAppointmentNumber)
			   ,MainCumlativePensionablePayYTD      = ytd.YTDMainPensionablePay/(select count(1) from #LGPSMonthlySummary tms where tms.PayDetailOriginalAppointmentNumber = ms.PayDetailOriginalAppointmentNumber)
			   ,[ID5050PensionablePayYTD]                  = ytd.YTD5050PensionablePay/(select count(1) from #LGPSMonthlySummary tms where tms.PayDetailOriginalAppointmentNumber = ms.PayDetailOriginalAppointmentNumber)
			   ,EmployeeAVCYTD                             = ytd.YTDEmployeeAVCAmount/(select count(1) from #LGPSMonthlySummary tms where tms.PayDetailOriginalAppointmentNumber = ms.PayDetailOriginalAppointmentNumber)
			   ,EmployerAVCYTD                    = ytd.YTDEmployerAVCAmount/(select count(1) from #LGPSMonthlySummary tms where tms.PayDetailOriginalAppointmentNumber = ms.PayDetailOriginalAppointmentNumber)
			   ,EmployeeAPCYTD                    = ytd.YTDEmployeeAPCAmount/(select count(1) from #LGPSMonthlySummary tms where tms.PayDetailOriginalAppointmentNumber = ms.PayDetailOriginalAppointmentNumber)
			   ,EmployerAPCYTD                    = ytd.YTDEmployerAPCAmount/(select count(1) from #LGPSMonthlySummary tms where tms.PayDetailOriginalAppointmentNumber = ms.PayDetailOriginalAppointmentNumber)


          FROM #LGPSMonthlySummary  ms
                INNER JOIN #LGPSYTD  ytd ON ms.PayDetailOriginalAppointmentNumber= ytd.[Original Appointment No_]
   END
ELSE
  BEGIN
         UPDATE #LGPSMonthlySummary 
            SET MainEmployeeContributionsYTD      = ytd.YTDEmployeeAmount
		       ,MainEmployerContributionsYTD          = ytd.YTDEmployerAmount
			   ,EmployerTotalPensionAmountYTD      = ytd.YTDEmployerTotalPensionAmount
	           ,[ID5050EmployeeContributionYTD]         = ytd.[YTD5050EmployeeAmount]
		       ,[ID5050EmployerContributionYTD]          = ytd.[YTD5050EmployerAmount]
		       ,EmployeeAddedYearsYTD                  = ytd.YTDEmployeeAddedYearsAmount
		       ,EmployerAddedYearsYTD                   = ytd.YTDEmployerAddedYearsAmount
			   ,MainCumlativePensionablePayYTD      = ytd.YTDMainPensionablePay
			   ,[ID5050PensionablePayYTD]                  = ytd.YTD5050PensionablePay
			   ,EmployeeAVCYTD                             = ytd.YTDEmployeeAVCAmount
			   ,EmployerAVCYTD                    = ytd.YTDEmployerAVCAmount
			   ,EmployeeAPCYTD                    = ytd.YTDEmployeeAPCAmount
			   ,EmployerAPCYTD                    = ytd.YTDEmployerAPCAmount

          FROM #LGPSMonthlySummary  ms
                INNER JOIN #LGPSYTD  ytd ON ms.PayDetailOriginalAppointmentNumber= ytd.[Original Appointment No_]
  END

       Update #LGPSMonthlySummary 
	     Set PeriodEmployeePensionTotalsOK = 'N'
		 WHERE [Period50_50EmployeeAmount]
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
   ms.[DfES_Area]                                                     as 'AppointmentCustomerDfesArea',
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
      ELSE ''

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
     [EPM$Appointment] APP with(nolock)
     LEFT JOIN [EPM$Pay Element]pe1 with(nolock) on app.[Allowance Code 1] = pe1.code and pe1.Pension = 1
	 LEFT JOIN [EPM$Pay Element]pe2 with(nolock) on app.[Allowance Code 2] = pe2.code and pe2.Pension = 1
	 LEFT JOIN [EPM$Pay Element]pe3 with(nolock) on app.[Allowance Code 3] = pe3.code and pe3.Pension = 1
	 LEFT JOIN [EPM$Pay Element]pe4 with(nolock) on app.[Allowance Code 4] = pe4.code and pe4.NI = 1    
  -- LEFT JOIN [EPM$Pension Scheme]   PEN  ON UPPER(pdl.reference )  = UPPER(PEN.[Scheme No_])
  where ms.PayDetailOriginalAppointmentNumber  = app.[Original Appointment]
    and app.[Effective Date] <= @PeriodEnd
	and app.no_ = (select max(app2.no_) from [EPM$Appointment] APP2 where app2.[Original Appointment] = app.[Original Appointment]
	               and app2.[Effective Date] <= @PeriodEnd)


   ) as tmp




  update  LG set lg.AppointmentResignationReason= replace([Description],',',' ')
   FROM  #OriginalAppointmentInfo LG  left join [EPM$Dictionary by Territory] DI  on lg.AppointmentResignationReason = di.Code and lg.AppointmentCustomerDfesArea = di.Territory
   where TYPE = 'RESIGNATION'


      

  update #OriginalAppointmentInfo set TaxableEarningsForPeriod =   (SELECT sum(amount)
                                                                     FROM [EPM$Pay Detail Line] pdl
                                                                         ,[EPM$Pay Element] pe
                                                                    where pe.Tax = 1
                                                                     and pe.Code = pdl.[Pay Element Code]
                                                                     and pdl.[Tax Year] = @TAXYEAR
													                 and ( (pdl.Period = @PERIOD) OR (@PERIOD=0) )
													                 and pdl.[Original Appointment No_] = #OriginalAppointmentInfo.AppointmentOriginalAppointment
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
	       [EPM$Appointment] app with(nolock)
		      LEFT JOIN [EPM$Pay Element]pe1 with(nolock) on app.[Allowance Code 1] = pe1.code and pe1.Pension = 1
	          LEFT JOIN [EPM$Pay Element]pe2 with(nolock) on app.[Allowance Code 2] = pe2.code and pe2.Pension = 1
	          LEFT JOIN [EPM$Pay Element]pe3 with(nolock) on app.[Allowance Code 3] = pe3.code and pe3.Pension = 1
	          LEFT JOIN [EPM$Pay Element]pe4 with(nolock) on app.[Allowance Code 4] = pe4.code and pe4.NI = 1  
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
						
   Update  oai
   SET AppointmentPartTimeHoursEffectiveFrom = a.[Effective Date]
   FROM #OriginalAppointmentInfo oai
   inner join [EPM$Appointment] a with(nolock) ON oai.AppointmentNo = a.No_
   inner join [EPM$Appointment] a2 with(nolock) ON oai.AppointmentOriginalAppointment = a2.No_
	   where a.[Total Hours] = a.[Full Time Hours] 

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

Print('Placeholder 3')	
   update ai 
   SET RowStatus = isnull((Select 'NewStarter'  where (PayDetailLineTaxYear = @TAXYEAR and ((PayDetailLinePeriod = @PERIOD) OR (@PERIOD=0)))  and not exists 
                                                  (select *
	                                                from [EPM$Pay Detail Line]pdl
					                                where  pdl.[Payroll Date]  <  PayDetailPayrollDate
						                              and pdl.[Pay Element Code] = 'PENSION'
						                              and pdl.[Original Appointment No_] =  AppointmentOriginalAppointment
		     			                              and pdl.[Payroll Group Code] = PayDetailPayrollGroupCode) ),'Current')  
	  ,RowHoursEffectiveFrom = isnull((Select min(app.[Effective Date]) 
						                  from [EPM$Appointment] app with(nolock), [EPM$Appointment] app2 with(nolock)
						                  where app.[Original Appointment] = AppointmentOriginalAppointment 
						                   and  isnull(app.[Total Hours],0) = AppointmentNormalHoursperWeek
		                                   and app.[Original Appointment] = app2.[Original Appointment]
		                                   and isnull(app2.[Total Hours],0) <> isnull(app.[Total Hours],0)
		                                    and app.[Effective Date] > app2.[Effective Date]										   
										    ),(Select min(app.[effective date]) 
                                                 from [EPM$Appointment] app with(nolock) 
                                                where app.[Original Appointment] = AppointmentOriginalAppointment
	                                              and app.[Total Hours] = AppointmentNormalHoursperWeek))





	  ,RowWeeksEffectiveFrom = isnull((Select min(app.[Effective Date]) 
						                  from [EPM$Appointment] app with(nolock) ,[EPM$Appointment] app2 with(nolock)
						                  where app.[Original Appointment] = AppointmentOriginalAppointment 
						                   and  isnull(app.[Weeks Worked],0) = app.[Weeks Worked]

										   and app.[Original Appointment] = app2.[Original Appointment]
		                                   and isnull(app2.[Weeks Worked],0) <> isnull(app.[Weeks Worked],0)
		                                    and app.[Effective Date] > app2.[Effective Date]	  
										   
										   ),AppointmentEffectiveDate)
	  ,RowSalaryEffectiveFrom = isnull((Select min(app.[Effective Date]) 
						                  from [EPM$Appointment] app with(nolock)  
						                  where app.[Original Appointment] = AppointmentOriginalAppointment 
						                   and  isnull(APP.[Salary Full Time],0) = AppointmentFullTimeSalary),AppointmentEffectiveDate)
	



	  ,OldAppFullTimeWeeks  =(Select app.[Full Time Weeks] from [EPM$Appointment] app with(nolock) where app.[no_] = AppointmentReissuedFrom )
      ,OldAppFullTimeHours  =(Select app.[Full Time Hours] from [EPM$Appointment] app with(nolock) where app.[no_] = AppointmentReissuedFrom )
			  
	  ,RowOldHours  =(Select app.[Total Hours] from [EPM$Appointment] app with(nolock) where app.[no_] = AppointmentReissuedFrom )

	  ,RowOldWeeks  =(Select app.[Weeks] from [EPM$Appointment] app with(nolock) where app.[no_] = AppointmentReissuedFrom )
	  			  
	  ,RowOldActual  =(Select app.[Salary Incl_ Allowances] from [EPM$Appointment] app with(nolock) where app.[no_] = AppointmentReissuedFrom )

	  ,RowOldFte  =(Select  cast( app.[Salary Full Time] + app.[Allowance Full Time Amount 1]
			     + app.[Allowance Full Time Amount 2]
				 + app.[Allowance Full Time Amount 3]
				 + app.[Allowance Full Time Amount 4]
				 + app.[TLR Amount]
				 + app.[Safeguard Total] as Decimal(10,2))    from [EPM$Appointment] app with(nolock) where app.[no_] = AppointmentReissuedFrom )

	 FROM  #LGPSMonthlySummary ms join #OriginalAppointmentInfo ai on ms.PayDetailOriginalAppointmentNumber  = ai.AppointmentOriginalAppointment

	  update  ai
   SET RowStatus = 'ChangeInPayPeriod' 
	FROM  #LGPSMonthlySummary ms join #OriginalAppointmentInfo ai on ms.PayDetailOriginalAppointmentNumber  = ai.AppointmentOriginalAppointment
	WHERE ((RowHoursEffectiveFrom >= AppointmentEffectiveDate) or (RowWeeksEffectiveFrom >= AppointmentEffectiveDate))
    and RowStatus <> 'NewStarter'
	and AppointmentEffectiveDate between ReportPayPeriodStart and ReportPayPeriodEnd

  update ai
   SET RowStatus = 'ChangeLog' 
   FROM  #LGPSMonthlySummary ms join #OriginalAppointmentInfo ai on ms.PayDetailOriginalAppointmentNumber  = ai.AppointmentOriginalAppointment
   left join [EPM$Change Log Entry] le with(nolock) on  ( ai.[AppointmentNo] = le.[Primary Key Field 1 Value]  
                                                                 -- or lgps.[AppReissuedTo] = le.[Primary Key Field 1 Value]
																 )
   where le.[Table No_] = 50001   
    and  le.[Field No_] in (100,101)
     and le.[Type of Change] = 1
	 and le.[Old Value] <> le.[New Value]
	 and cast(le.[Date and Time] as date) between ms.ReportPayPeriodStart and ms.ReportPayPeriodEnd
	 and ai.RowStatus <> 'NewStarter'

Print('Placeholder 4')

	update #OriginalAppointmentInfo
	set AppointmentFullTimeSalaryIncludingAllowances = RowOldFTE
	where ISNULL(AppointmentReissuedFrom, '') <> ''

	ALTER TABLE #OriginalAppointmentInfo ADD OldLGSSPartTimeHours Decimal(9,2)  


	--------------------------------------------------------------------------------------------------------------
	
	--UPDATE #OriginalAppointmentInfo SET OldLGSSPartTimeHours = (RowOldHours * RowOldWeeks) / OldAppFullTimeWeeks
	UPDATE #OriginalAppointmentInfo SET OldLGSSPartTimeHours = (RowOldHours * RowOldWeeks) / nullif(OldAppFullTimeWeeks,0)
	
	--------------------------------------------------------------------------------------------------------------



  IF @PERIOD = 0 
   BEGIN
    Update #LGPSMonthlySummary 
      set Pen8FTEAmount=null,Pen8WeeksWorkedAmount=null
    where PayDetailOriginalAppointmentNumber in (select app.[Original Appointment]  
         from [EPM$Appointment] app where isNull(app.[Resignation Date],'1753-01-01') > @PeriodStart )
  END
 ELSE
  BEGIN	
   Update #LGPSMonthlySummary 
      set Pen8FTEAmount=null,Pen8WeeksWorkedAmount=null
    where PayDetailOriginalAppointmentNumber in (select app.[Original Appointment]  
         from [EPM$Appointment] app where isNull(app.[Resignation Date],'1753-01-01') > @PEN8PeriodStart13 
		                                                         and isNull(app.[Resignation Date],'1753-01-01') <  @PeriodStart )
 END
 Print('Placeholder 5')
 -- Print @SQLString
	exec sp_executesql @SQLString--, N'@flPeriodStart date, @flPeriodEnd date', @PeriodStart, @PeriodEnd
Print('Placeholder 6')	
		/*
	SELECT * FROM #LGPSMonthlySummary  ms
		LEFT JOIN #OriginalAppointmentInfo ai on ms.PayDetailOriginalAppointmentNumber= ai.AppointmentOriginalAppointment
	*/





