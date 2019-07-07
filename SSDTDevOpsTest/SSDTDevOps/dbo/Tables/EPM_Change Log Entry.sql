CREATE TABLE [dbo].[EPM$Change Log Entry] (
    [timestamp]                 ROWVERSION    NOT NULL,
    [Entry No_]                 BIGINT        IDENTITY (1, 1) NOT NULL,
    [Date and Time]             DATETIME      NOT NULL,
    [Time]                      DATETIME      NOT NULL,
    [User ID]                   VARCHAR (20)  NOT NULL,
    [Table No_]                 INT           NOT NULL,
    [Field No_]                 INT           NOT NULL,
    [Type of Change]            INT           NOT NULL,
    [Old Value]                 VARCHAR (250) NOT NULL,
    [New Value]                 VARCHAR (250) NOT NULL,
    [Primary Key]               VARCHAR (250) NOT NULL,
    [Primary Key Field 1 No_]   INT           NOT NULL,
    [Primary Key Field 1 Value] VARCHAR (50)  NOT NULL,
    [Primary Key Field 2 No_]   INT           NOT NULL,
    [Primary Key Field 2 Value] VARCHAR (50)  NOT NULL,
    [Primary Key Field 3 No_]   INT           NOT NULL,
    [Primary Key Field 3 Value] VARCHAR (50)  NOT NULL,
    [Worktray Originated]       TINYINT       NOT NULL,
    CONSTRAINT [EPM$Change Log Entry$0] PRIMARY KEY CLUSTERED ([Entry No_] ASC) WITH (FILLFACTOR = 99)
);

