-- Supporto alla distinta corrente. Installare insieme al pacchetto applicativo completo.
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @Versione INT = 2026111701;
    DECLARE @Codice NVARCHAR(50) = N'TEC-016-VERSIONE-CONTENUTO';
    DECLARE @Script NVARCHAR(260) = N'TEC-016_13_Versione_Contenuto_Distinta.sql';
    DECLARE @Impronta CHAR(64) = 'C5DD9E501B594B85EDA829CD21620E9D31E178A30024EF6C66F1516679FCC2DD';

    IF NOT EXISTS (SELECT 1 FROM dbo.VersioniSchema WITH (UPDLOCK, HOLDLOCK)
                   WHERE Versione = 2026111602 AND CodiceIntervento = N'TEC-016-STATO-SNAPSHOT')
        THROW 53900, 'Versione prerequisito 2026111602 non installata.', 1;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione > @Versione)
        THROW 53901, 'Il database contiene una versione successiva.', 1;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione = @Versione
               AND CodiceIntervento = @Codice AND NomeScript = @Script AND ImprontaSha256 = @Impronta)
    BEGIN
        COMMIT TRANSACTION;
        RETURN;
    END;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione = @Versione
               OR CodiceIntervento = @Codice OR NomeScript = @Script)
        THROW 53902, 'Versione gia registrata con metadati differenti.', 1;

/* PAYLOAD TEC-016-VERSIONE-CONTENUTO START */
    ALTER TABLE dbo.DistinteBaseRevisioni ADD VersioneContenuto BIGINT NOT NULL
        CONSTRAINT DF_DistinteBaseRevisioni_VersioneContenuto DEFAULT (0);

    ALTER TABLE dbo.PreventiviRighe ADD VersioneDistintaApplicata BIGINT NULL;

    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER dbo.TR_DistintaBaseNodi_VersioneDistinta
ON dbo.DistintaBaseNodi
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH NodiInteressati AS
    (
        SELECT IdRevisioneDistinta FROM inserted
        UNION
        SELECT IdRevisioneDistinta FROM deleted
    ),
    RevisioniInteressate AS
    (
        SELECT DISTINCT i.IdRevisioneDistinta
        FROM NodiInteressati AS i
    )
    UPDATE revisione
    SET VersioneContenuto = VersioneContenuto + 1
    FROM dbo.DistinteBaseRevisioni AS revisione
    JOIN RevisioniInteressate AS i ON i.IdRevisioneDistinta = revisione.IdRevisioneDistinta;
END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER dbo.TR_DistintaMateriali_VersioneDistinta
ON dbo.DistintaMateriali
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH NodiInteressati AS
    (
        SELECT IdNodoDistinta FROM inserted
        UNION
        SELECT IdNodoDistinta FROM deleted
    ),
    RevisioniInteressate AS
    (
        SELECT DISTINCT n.IdRevisioneDistinta
        FROM NodiInteressati AS i
        JOIN dbo.DistintaBaseNodi AS n ON n.IdNodoDistinta = i.IdNodoDistinta
    )
    UPDATE revisione
    SET VersioneContenuto = VersioneContenuto + 1
    FROM dbo.DistinteBaseRevisioni AS revisione
    JOIN RevisioniInteressate AS i ON i.IdRevisioneDistinta = revisione.IdRevisioneDistinta;
END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER dbo.TR_DistintaLavorazioni_VersioneDistinta
ON dbo.DistintaLavorazioni
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH NodiInteressati AS
    (
        SELECT IdNodoDistinta FROM inserted
        UNION
        SELECT IdNodoDistinta FROM deleted
    ),
    RevisioniInteressate AS
    (
        SELECT DISTINCT n.IdRevisioneDistinta
        FROM NodiInteressati AS i
        JOIN dbo.DistintaBaseNodi AS n ON n.IdNodoDistinta = i.IdNodoDistinta
    )
    UPDATE revisione
    SET VersioneContenuto = VersioneContenuto + 1
    FROM dbo.DistinteBaseRevisioni AS revisione
    JOIN RevisioniInteressate AS i ON i.IdRevisioneDistinta = revisione.IdRevisioneDistinta;
END;';
/* PAYLOAD TEC-016-VERSIONE-CONTENUTO END */

    INSERT dbo.VersioniSchema (Versione, CodiceIntervento, NomeScript, Descrizione, ImprontaSha256)
    VALUES (@Versione, @Codice, @Script, N'Indicatore tecnico per le modifiche al contenuto della distinta.', @Impronta);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
