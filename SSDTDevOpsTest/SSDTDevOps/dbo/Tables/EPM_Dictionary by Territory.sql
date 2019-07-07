CREATE TABLE [dbo].[EPM$Dictionary by Territory] (
    [timestamp]                  ROWVERSION   NOT NULL,
    [Code]                       VARCHAR (20) NOT NULL,
    [Type]                       VARCHAR (20) NOT NULL,
    [Territory]                  VARCHAR (10) NOT NULL,
    [Short Code]                 VARCHAR (10) NOT NULL,
    [Exempted Customer Code]     VARCHAR (20) NOT NULL,
    [Description]                VARCHAR (50) NOT NULL,
    [Police Check Required]      TINYINT      NOT NULL,
    [LGPS Pensionable]           TINYINT      NOT NULL,
    [Exclude From Web]           TINYINT      NOT NULL,
    [Miracle Employment Status]  INT          NOT NULL,
    [Primary Ethnic Code]        VARCHAR (20) NOT NULL,
    [Primary Ethnic Description] VARCHAR (50) NOT NULL,
    CONSTRAINT [EPM$Dictionary by Territory$0] PRIMARY KEY CLUSTERED ([Code] ASC, [Type] ASC, [Territory] ASC, [Short Code] ASC, [Exempted Customer Code] ASC) WITH (FILLFACTOR = 99)
);

