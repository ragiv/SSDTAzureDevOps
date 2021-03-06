﻿CREATE TABLE [dbo].[EPM$Payroll Employee] (
    [timestamp]                   ROWVERSION       NOT NULL,
    [No_]                         VARCHAR (20)     NOT NULL,
    [Search Name]                 VARCHAR (30)     NOT NULL,
    [Surname]                     VARCHAR (30)     NOT NULL,
    [Forenames]                   VARCHAR (30)     NOT NULL,
    [Title]                       VARCHAR (5)      NOT NULL,
    [Sex]                         INT              NOT NULL,
    [Global Dimension 1 Code]     VARCHAR (20)     NOT NULL,
    [Director]                    TINYINT          NOT NULL,
    [Director Since]              INT              NOT NULL,
    [Pay Status]                  INT              NOT NULL,
    [Job Title_Grade]             VARCHAR (50)     NOT NULL,
    [Global Dimension 2 Code]     VARCHAR (20)     NOT NULL,
    [Tax Code]                    VARCHAR (8)      NOT NULL,
    [Tax Basis]                   INT              NOT NULL,
    [Taxable Pay (P45)]           DECIMAL (38, 20) NOT NULL,
    [Tax Paid (P45)]              DECIMAL (38, 20) NOT NULL,
    [Paid up to Period]           INT              NOT NULL,
    [Pay Rounding]                DECIMAL (38, 20) NOT NULL,
    [Amount To Be Paid]           DECIMAL (38, 20) NOT NULL,
    [NI Number]                   VARCHAR (30)     NOT NULL,
    [NI Letter]                   INT              NOT NULL,
    [NI Holiday]                  TINYINT          NOT NULL,
    [Pay Frequency]               INT              NOT NULL,
    [Rate Indicator]              INT              NOT NULL,
    [Rate]                        DECIMAL (38, 20) NOT NULL,
    [Hours per Period]            DECIMAL (38, 20) NOT NULL,
    [Basic Pay]                   DECIMAL (38, 20) NOT NULL,
    [Address]                     VARCHAR (50)     NOT NULL,
    [Address 2]                   VARCHAR (50)     NOT NULL,
    [City]                        VARCHAR (30)     NOT NULL,
    [Post Code]                   VARCHAR (20)     NOT NULL,
    [Phone No_]                   VARCHAR (30)     NOT NULL,
    [County]                      VARCHAR (30)     NOT NULL,
    [Mobile Phone No_]            VARCHAR (30)     NOT NULL,
    [Extension]                   VARCHAR (30)     NOT NULL,
    [Pager]                       VARCHAR (30)     NOT NULL,
    [Payment Method]              INT              NOT NULL,
    [Bank Name]                   VARCHAR (30)     NOT NULL,
    [Bank Branch]                 VARCHAR (30)     NOT NULL,
    [Account Name]                VARCHAR (30)     NOT NULL,
    [Sort Code]                   VARCHAR (8)      NOT NULL,
    [Account No_]                 VARCHAR (8)      NOT NULL,
    [Building Society Account]    VARCHAR (20)     NOT NULL,
    [BOBS_AutoPay]                VARCHAR (6)      NOT NULL,
    [Date of Birth]               DATETIME         NOT NULL,
    [Join Date]                   DATETIME         NOT NULL,
    [Leave Date]                  DATETIME         NOT NULL,
    [Holidays (Allowed)]          DECIMAL (38, 20) NOT NULL,
    [Holidays (Taken)]            DECIMAL (38, 20) NOT NULL,
    [Exclusion Code]              VARCHAR (1)      NOT NULL,
    [Exclusion End Date]          DATETIME         NOT NULL,
    [Marital Status]              INT              NOT NULL,
    [P45 Printed]                 TINYINT          NOT NULL,
    [Picture]                     IMAGE            NULL,
    [Create Date]                 DATETIME         NOT NULL,
    [Last Date Modified]          DATETIME         NOT NULL,
    [Posting Group]               VARCHAR (10)     NOT NULL,
    [No_ Series]                  VARCHAR (10)     NOT NULL,
    [E-Mail]                      VARCHAR (80)     NOT NULL,
    [Company E-Mail]              VARCHAR (80)     NOT NULL,
    [Resource No_]                VARCHAR (20)     NOT NULL,
    [Holiday Accrual Scheme No_]  VARCHAR (10)     NOT NULL,
    [SSP Start Cycle Date]        DATETIME         NOT NULL,
    [SSP Made Up To Basic]        TINYINT          NOT NULL,
    [SSP1(L) Start Date]          DATETIME         NOT NULL,
    [SSP1(L) Last Date]           DATETIME         NOT NULL,
    [SSP1(L) No_ of Weeks]        INT              NOT NULL,
    [Payroll Group Code]          VARCHAR (10)     NOT NULL,
    [Student Loan]                TINYINT          NOT NULL,
    [APP]                         TINYINT          NOT NULL,
    [Director Pay On Account]     TINYINT          NOT NULL,
    [Exclude Employer NI Contrib] TINYINT          NOT NULL,
    [Ni Pension Adjustment]       TINYINT          NOT NULL,
    [Expected Pension Date]       DATETIME         NOT NULL,
    [Obsolete 331]                TINYINT          NOT NULL,
    [P45 Part3 Print Required]    TINYINT          NOT NULL,
    [PreTax Reference]            VARCHAR (10)     NOT NULL,
    [PreTax Office]               VARCHAR (40)     NOT NULL,
    [PreTax District]             VARCHAR (3)      NOT NULL,
    [PreLeave Date]               DATETIME         NOT NULL,
    [PreStudentLoan]              TINYINT          NOT NULL,
    [PreTax Code]                 VARCHAR (8)      NOT NULL,
    [PreWeekApplied]              TINYINT          NOT NULL,
    [PreWeek]                     INT              NOT NULL,
    [PreMonth]                    INT              NOT NULL,
    [PrePaid]                     TINYINT          NOT NULL,
    [PreP11Deductions]            DECIMAL (38, 20) NOT NULL,
    [Starter Statement]           INT              NOT NULL,
    [Deceased]                    TINYINT          NOT NULL,
    [Last Date P45 Part1 Created] DATETIME         NOT NULL,
    [Apprentice]                  TINYINT          NOT NULL,
    [Starter Submission Created]  DATETIME         NOT NULL,
    [EEA or Commonwealth Citizen] TINYINT          NOT NULL,
    [EPM6 Scheme]                 TINYINT          NOT NULL,
    [Seconded Employee (Expat)]   TINYINT          NOT NULL,
    [HR Employee No_]             VARCHAR (20)     NOT NULL,
    [Create P45 XML]              TINYINT          NOT NULL,
    [EDOCS]                       TINYINT          NOT NULL,
    [Reason For Leaving]          INT              NOT NULL,
    [NINO Verification Requested] DATETIME         NOT NULL,
    [NINO Verified]               DATETIME         NOT NULL,
    [NINO Verify Failed]          DATETIME         NOT NULL,
    [Country Code]                VARCHAR (10)     NOT NULL,
    [Passport Number]             VARCHAR (35)     NOT NULL,
    [Previous No_]                VARCHAR (20)     NOT NULL,
    [Normal Hours per Week]       DECIMAL (38, 20) NOT NULL,
    [Starting Declaration]        INT              NOT NULL,
    [Originating Employee No_]    VARCHAR (20)     NOT NULL,
    [LatePaymentReason]           INT              NOT NULL,
    [NI Only Employment]          TINYINT          NOT NULL,
    [P45 Week_Month]              INT              NOT NULL,
    [Plan 2]                      TINYINT          NOT NULL,
    [NotGenderPay]                TINYINT          NOT NULL,
    [Post Graduate Loan]          TINYINT          NOT NULL,
    [PrePostGradLoan]             TINYINT          NOT NULL,
    CONSTRAINT [EPM$Payroll Employee$0] PRIMARY KEY CLUSTERED ([No_] ASC) WITH (FILLFACTOR = 99)
);

