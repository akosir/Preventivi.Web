-- Decisioni 352-356. Invio esplicito e conservazione dei documenti.
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @Versione INT = 2026112401;
    DECLARE @Codice NVARCHAR(50) = N'TEC-018-INVIO';
    DECLARE @Script NVARCHAR(260) = N'TEC-018_02_Invio_Documenti_Storici.sql';
    DECLARE @Impronta CHAR(64) = 'ED537E9C63E0CEA1600A38A0ECD64DB9282BC17A6D928DF233925ADD67F317B2';
    IF NOT EXISTS (SELECT 1 FROM dbo.VersioniSchema WITH (UPDLOCK, HOLDLOCK)
                   WHERE Versione = 2026112302 AND CodiceIntervento = N'TEC-018-ORDINI-BOZZA')
        THROW 53896, 'Versione prerequisito 2026112302 non installata.', 1;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione > @Versione)
        THROW 53897, 'Il database contiene una versione successiva.', 1;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione = @Versione AND CodiceIntervento = @Codice
               AND NomeScript = @Script AND ImprontaSha256 = @Impronta)
    BEGIN
        COMMIT TRANSACTION;
        RETURN;
    END;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione = @Versione OR CodiceIntervento = @Codice OR NomeScript = @Script)
        THROW 53898, 'Versione gia registrata con metadati differenti.', 1;

/* PAYLOAD TEC-018-INVIO START */
    IF COL_LENGTH(N'dbo.OrdiniFornitori', N'DataInvio') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.OrdiniFornitori ADD DataInvio DATETIME2(0) NULL;';
    IF COL_LENGTH(N'dbo.OrdiniFornitori', N'UtenteInvio') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.OrdiniFornitori ADD UtenteInvio NVARCHAR(256) NULL;';
    IF COL_LENGTH(N'dbo.OrdiniFornitoriAudit', N'Motivazione') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.OrdiniFornitoriAudit ADD Motivazione NVARCHAR(500) NULL;';
    IF COL_LENGTH(N'dbo.OrdiniFornitoriAudit', N'StatoPrecedente') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.OrdiniFornitoriAudit ADD StatoPrecedente NVARCHAR(30) NULL;';
    IF COL_LENGTH(N'dbo.OrdiniFornitoriAudit', N'StatoNuovo') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.OrdiniFornitoriAudit ADD StatoNuovo NVARCHAR(30) NULL;';
    IF OBJECT_ID(N'dbo.OrdiniFornitoriDocumenti', N'U') IS NULL
        EXEC sys.sp_executesql N'CREATE TABLE dbo.OrdiniFornitoriDocumenti
        (
            IdDocumento INT IDENTITY PRIMARY KEY, IdOrdineFornitore INT NOT NULL,
            NumeroVersione INT NOT NULL, ConfermatoIl DATETIME2(0) NOT NULL, ConfermatoDa NVARCHAR(256) NOT NULL,
            TestataJson NVARCHAR(MAX) NOT NULL, RigheJson NVARCHAR(MAX) NOT NULL,
            CONSTRAINT FK_OrdiniFornitoriDocumenti_Ordine FOREIGN KEY (IdOrdineFornitore) REFERENCES dbo.OrdiniFornitori(IdOrdineFornitore),
            CONSTRAINT UQ_OrdiniFornitoriDocumenti_Versione UNIQUE (IdOrdineFornitore, NumeroVersione),
            CONSTRAINT CK_OrdiniFornitoriDocumenti_Json CHECK (ISJSON(TestataJson) = 1 AND ISJSON(RigheJson) = 1),
            CONSTRAINT CK_OrdiniFornitoriDocumenti_Versione CHECK (NumeroVersione > 0)
        );';
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.OrdiniFornitori_Documenti_Elenco @IdOrdine INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT IdDocumento, IdOrdineFornitore, NumeroVersione, ConfermatoIl, ConfermatoDa
    FROM dbo.OrdiniFornitoriDocumenti WHERE IdOrdineFornitore = @IdOrdine
    ORDER BY NumeroVersione DESC;
END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.OrdiniFornitori_Documenti_Dettaglio @IdOrdine INT, @IdDocumento INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (1) * FROM dbo.OrdiniFornitoriDocumenti
    WHERE IdOrdineFornitore = @IdOrdine AND (@IdDocumento IS NULL OR IdDocumento = @IdDocumento)
    ORDER BY NumeroVersione DESC;
END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.OrdiniFornitori_ConfermaInvio
    @IdOrdine INT, @VersioneOrdine BINARY(8), @Utente NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
    IF @Utente IS NULL THROW 54101, ''Utente richiesto.'', 1;
    DECLARE @IdDocumento INT;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.OrdiniFornitori WITH (UPDLOCK, HOLDLOCK) WHERE IdOrdineFornitore = @IdOrdine)
            THROW 54103, ''Ordine non trovato.'', 1;
        IF @VersioneOrdine IS NULL OR NOT EXISTS
            (SELECT 1 FROM dbo.OrdiniFornitori WHERE IdOrdineFornitore = @IdOrdine AND VersioneRiga = @VersioneOrdine)
            THROW 54104, ''Ordine modificato da altro utente.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.OrdiniFornitori WHERE IdOrdineFornitore = @IdOrdine AND Stato = N''Bozza'')
            THROW 54105, ''Conferma consentita in Bozza.'', 1;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.Fornitori AS f WITH (UPDLOCK, HOLDLOCK)
            JOIN dbo.OrdiniFornitori AS o ON o.IdFornitore = f.IdFornitore
            WHERE o.IdOrdineFornitore = @IdOrdine AND f.Attivo = 1
        )
            THROW 54102, ''Fornitore non attivo.'', 1;
        DECLARE @Righe INT;
        SELECT @Righe = COUNT(*) FROM dbo.OrdiniFornitoriRighe WITH (UPDLOCK, HOLDLOCK)
        WHERE IdOrdineFornitore = @IdOrdine;
        IF NOT EXISTS (SELECT 1 FROM dbo.OrdiniFornitoriRighe
                       WHERE IdOrdineFornitore = @IdOrdine AND TipoRiga IN (N''Materiale'', N''Lavorazione''))
            THROW 54122, ''Manca una riga economica.'', 1;
        IF EXISTS
        (
            SELECT 1 FROM dbo.OrdiniFornitoriRighe
            WHERE IdOrdineFornitore = @IdOrdine
              AND (Quantita <= 0 OR PrezzoUnitario < 0 OR NULLIF(LTRIM(RTRIM(Descrizione)), N'''') IS NULL
                   OR TipoRiga NOT IN (N''Materiale'', N''Lavorazione'', N''Nota''))
        )
            THROW 54123, ''Dati riga non validi per l invio.'', 1;
        UPDATE dbo.OrdiniFornitoriRighe
        SET PrezzoUnitario = CASE WHEN TipoRiga = N''Nota'' THEN 0 ELSE PrezzoUnitario END,
            TotaleRiga = CASE WHEN TipoRiga = N''Nota'' THEN 0 ELSE ROUND(Quantita * PrezzoUnitario, 2) END
        WHERE IdOrdineFornitore = @IdOrdine;
        DECLARE @Istante DATETIME2(0) = SYSDATETIME();
        UPDATE dbo.OrdiniFornitori
        SET Stato = N''Inviato'', DataInvio = @Istante, UtenteInvio = @Utente,
            TotaleOrdine = (SELECT COALESCE(SUM(TotaleRiga), 0) FROM dbo.OrdiniFornitoriRighe WHERE IdOrdineFornitore = @IdOrdine),
            DataModifica = @Istante, UtenteModifica = @Utente
        WHERE IdOrdineFornitore = @IdOrdine AND VersioneRiga = @VersioneOrdine;
        IF @@ROWCOUNT <> 1 THROW 54104, ''Ordine modificato durante la conferma.'', 1;
        DECLARE @Testata NVARCHAR(MAX) =
        (
            SELECT o.*, f.CodiceFornitore, f.RagioneSociale, f.PartitaIVA, f.CodiceFiscale,
                   f.Indirizzo, f.CAP, f.Citta, f.Provincia, f.Telefono, f.Email, f.Referente
            FROM dbo.OrdiniFornitori AS o JOIN dbo.Fornitori AS f ON f.IdFornitore = o.IdFornitore
            WHERE o.IdOrdineFornitore = @IdOrdine
            FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
        );
        DECLARE @RigheJson NVARCHAR(MAX) =
        (
            SELECT * FROM dbo.OrdiniFornitoriRighe WHERE IdOrdineFornitore = @IdOrdine
            ORDER BY RigaNr FOR JSON PATH, INCLUDE_NULL_VALUES
        );
        DECLARE @NumeroVersione INT =
            COALESCE((SELECT MAX(NumeroVersione) FROM dbo.OrdiniFornitoriDocumenti WITH (UPDLOCK, HOLDLOCK)
                      WHERE IdOrdineFornitore = @IdOrdine), 0) + 1;
        INSERT dbo.OrdiniFornitoriDocumenti
            (IdOrdineFornitore, NumeroVersione, ConfermatoIl, ConfermatoDa, TestataJson, RigheJson)
        VALUES (@IdOrdine, @NumeroVersione, @Istante, @Utente, @Testata, @RigheJson);
        SET @IdDocumento = CONVERT(INT, SCOPE_IDENTITY());
        INSERT dbo.OrdiniFornitoriAudit
            (IdOrdineFornitore, Operazione, Utente, DataOperazione, StatoPrecedente, StatoNuovo)
        VALUES (@IdOrdine, N''Invio'', @Utente, @Istante, N''Bozza'', N''Inviato'');
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
    SELECT @IdDocumento;
END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.OrdiniFornitori_Riapri
    @IdOrdine INT, @VersioneOrdine BINARY(8), @Motivazione NVARCHAR(500), @Utente NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    SET @Motivazione = NULLIF(LTRIM(RTRIM(@Motivazione)), N'''');
    SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
    IF @Utente IS NULL THROW 54101, ''Utente richiesto.'', 1;
    IF @Motivazione IS NULL THROW 54126, ''Motivazione amministrativa richiesta.'', 1;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.OrdiniFornitori WITH (UPDLOCK, HOLDLOCK) WHERE IdOrdineFornitore = @IdOrdine)
            THROW 54103, ''Ordine non trovato.'', 1;
        IF @VersioneOrdine IS NULL OR NOT EXISTS
            (SELECT 1 FROM dbo.OrdiniFornitori WHERE IdOrdineFornitore = @IdOrdine AND VersioneRiga = @VersioneOrdine)
            THROW 54104, ''Ordine modificato da altro utente.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.OrdiniFornitori WHERE IdOrdineFornitore = @IdOrdine AND Stato = N''Inviato'')
            THROW 54124, ''La riapertura richiede lo stato Inviato.'', 1;
        IF EXISTS (SELECT 1 FROM dbo.OrdiniFornitoriRighe WITH (UPDLOCK, HOLDLOCK)
                   WHERE IdOrdineFornitore = @IdOrdine AND QuantitaRicevuta <> 0)
            THROW 54125, ''Esistono ricezioni.'', 1;
        UPDATE dbo.OrdiniFornitori
        SET Stato = N''Bozza'', DataInvio = NULL, UtenteInvio = NULL, DataModifica = SYSDATETIME(), UtenteModifica = @Utente
        WHERE IdOrdineFornitore = @IdOrdine AND VersioneRiga = @VersioneOrdine;
        IF @@ROWCOUNT <> 1 THROW 54104, ''Ordine modificato durante la riapertura.'', 1;
        INSERT dbo.OrdiniFornitoriAudit
            (IdOrdineFornitore, Operazione, Utente, DataOperazione, Motivazione, StatoPrecedente, StatoNuovo)
        VALUES (@IdOrdine, N''Riapertura amministrativa'', @Utente, SYSDATETIME(), @Motivazione, N''Inviato'', N''Bozza'');
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER dbo.TR_OrdiniFornitoriDocumenti_Immutabili
ON dbo.OrdiniFornitoriDocumenti AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM deleted) OR EXISTS (SELECT 1 FROM inserted)
        THROW 54127, ''I documenti inviati sono immutabili.'', 1;
END;';
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.OrdiniFornitori_Dipendenze @IdOrdine INT, @IdRiga INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Sql NVARCHAR(MAX);
    SELECT @Sql = STRING_AGG(CONVERT(NVARCHAR(MAX),
        N''SELECT N'''''' + CASE WHEN t.name = N''OrdiniFornitoriDocumenti'' THEN N''Documenti inviati'' ELSE N''Riferimenti collegati'' END
        + N'''''' AS Tipo, COUNT_BIG(*) AS Numero FROM ''
        + QUOTENAME(SCHEMA_NAME(t.schema_id)) + N''.'' + QUOTENAME(t.name)
        + N'' WITH (UPDLOCK, HOLDLOCK) WHERE '' + QUOTENAME(c.name)
        + CASE WHEN fk.referenced_object_id = OBJECT_ID(N''dbo.OrdiniFornitori'')
               THEN N'' = @IdOrdine AND @IdRiga IS NULL''
               ELSE N'' IN (SELECT IdRigaOrdineFornitore FROM dbo.OrdiniFornitoriRighe WHERE IdOrdineFornitore = @IdOrdine
                        AND (@IdRiga IS NULL OR IdRigaOrdineFornitore = @IdRiga))'' END
        + N'' HAVING COUNT_BIG(*) > 0''), N'' UNION ALL '')
    FROM sys.foreign_key_columns AS fk
    JOIN sys.tables AS t ON t.object_id = fk.parent_object_id
    JOIN sys.columns AS c ON c.object_id = t.object_id AND c.column_id = fk.parent_column_id
    WHERE fk.referenced_object_id IN (OBJECT_ID(N''dbo.OrdiniFornitori''), OBJECT_ID(N''dbo.OrdiniFornitoriRighe''))
      AND fk.parent_object_id NOT IN (OBJECT_ID(N''dbo.OrdiniFornitoriRighe''), OBJECT_ID(N''dbo.OrdiniFornitoriAudit''));
    SET @Sql = COALESCE(@Sql + N'' UNION ALL '', N'''')
        + N''SELECT N''''Allegati'''' AS Tipo, COUNT_BIG(*) AS Numero FROM dbo.Allegati WITH (UPDLOCK, HOLDLOCK)
             WHERE (@IdRiga IS NULL AND Entita = N''''OrdiniFornitori'''' AND IdEntita = @IdOrdine)
                OR (Entita = N''''OrdiniFornitoriRighe'''' AND IdEntita IN
                    (SELECT IdRigaOrdineFornitore FROM dbo.OrdiniFornitoriRighe WHERE IdOrdineFornitore = @IdOrdine
                     AND (@IdRiga IS NULL OR IdRigaOrdineFornitore = @IdRiga))) HAVING COUNT_BIG(*) > 0'';
    EXEC sys.sp_executesql @Sql, N''@IdOrdine INT, @IdRiga INT'', @IdOrdine, @IdRiga;
END;';
/* PAYLOAD TEC-018-INVIO END */

    INSERT dbo.VersioniSchema (Versione, CodiceIntervento, NomeScript, Descrizione, ImprontaSha256)
    VALUES (@Versione, @Codice, @Script, N'Invio ordini con documento storico immutabile e riapertura amministrativa motivata.', @Impronta);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
