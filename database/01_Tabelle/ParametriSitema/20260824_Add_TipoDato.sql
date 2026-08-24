ALTER TABLE dbo.ParametriSistema
ADD TipoDato NVARCHAR(30) NOT NULL
    CONSTRAINT DF_ParametriSistema_TipoDato
    DEFAULT N'Stringa';
GO

ALTER TABLE dbo.ParametriSistema
ADD CONSTRAINT CK_ParametriSistema_TipoDato
CHECK
(
    TipoDato IN
    (
        N'Stringa',
        N'Intero',
        N'Decimale',
        N'Booleano',
        N'Data'
    )
);
GO