/*
    TEC-008 - Tipo riga esplicito nei modelli preventivo

    - aggiunge IdTipoRiga alle righe modello;
    - migra automaticamente soltanto le righe con un solo tipo attivo
      compatibile;
    - interrompe l'esecuzione e mostra le righe da classificare quando il
      tipo manca, e ambiguo o non e coerente;
    - applica NOT NULL, indice e chiave esterna;
    - elimina la selezione TOP (1) dalla creazione da modello;
    - mantiene coerenti la procedura storica e l'importazione da staging.

    Se la migrazione si interrompe, la colonna nullable rimane disponibile:
    valorizzare manualmente IdTipoRiga sulle righe mostrate e rieseguire lo
    script. Nessun preventivo viene creato o modificato dalla migrazione.

    Lo script non seleziona il database.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
GO

IF OBJECT_ID(N'dbo.ModelliPreventivoRighe', N'U') IS NULL
   OR OBJECT_ID(N'dbo.TipiRigaPreventivo', N'U') IS NULL
   OR OBJECT_ID(N'dbo.Preventivi', N'U') IS NULL
   OR OBJECT_ID(N'dbo.PreventiviRighe', N'U') IS NULL
   OR OBJECT_ID(N'dbo.ModelliPreventivo', N'U') IS NULL
   OR OBJECT_ID(N'dbo.Clienti', N'U') IS NULL
   OR OBJECT_ID(N'dbo.RichiesteClienti', N'U') IS NULL
   OR OBJECT_ID(N'dbo.Articoli', N'U') IS NULL
   OR OBJECT_ID(N'dbo.ModelliCiclo', N'U') IS NULL
   OR OBJECT_ID(N'dbo.ImportModelliPreventivo_Righe', N'U') IS NULL
   OR OBJECT_ID(N'dbo.ImportModelliPreventivo_Testata', N'U') IS NULL
   OR OBJECT_ID(N'dbo.sp_RicalcolaTotaliPreventivo', N'P') IS NULL
BEGIN
    THROW 51800, 'TEC-008: schema richiesto non disponibile.', 1;
END;
GO

IF COL_LENGTH(N'dbo.ModelliPreventivoRighe', N'IdTipoRiga') IS NULL
BEGIN
    ALTER TABLE dbo.ModelliPreventivoRighe
        ADD IdTipoRiga INT NULL;
END;
GO

UPDATE rigaModello
SET IdTipoRiga = tipoUnivoco.IdTipoRiga
FROM dbo.ModelliPreventivoRighe AS rigaModello
CROSS APPLY
(
    SELECT MIN(tipo.IdTipoRiga) AS IdTipoRiga
    FROM dbo.TipiRigaPreventivo AS tipo
    WHERE tipo.Attiva = 1
      AND
      (
          (rigaModello.IdArticolo IS NOT NULL AND tipo.RigaArticolo = 1)
          OR
          (rigaModello.IdArticolo IS NULL AND tipo.RigaLibera = 1)
      )
    HAVING COUNT(*) = 1
) AS tipoUnivoco
WHERE rigaModello.IdTipoRiga IS NULL;
GO

IF EXISTS
(
    SELECT 1
    FROM dbo.ModelliPreventivoRighe AS rigaModello
    LEFT JOIN dbo.TipiRigaPreventivo AS tipoAssegnato
        ON tipoAssegnato.IdTipoRiga = rigaModello.IdTipoRiga
    WHERE rigaModello.IdTipoRiga IS NULL
       OR tipoAssegnato.IdTipoRiga IS NULL
       OR NOT
          (
              (rigaModello.IdArticolo IS NOT NULL AND tipoAssegnato.RigaArticolo = 1)
              OR
              (rigaModello.IdArticolo IS NULL AND tipoAssegnato.RigaLibera = 1)
          )
)
BEGIN
    SELECT
        modello.CodiceModelloPreventivo,
        rigaModello.IdRigaModelloPreventivo,
        rigaModello.RigaNr,
        rigaModello.IdArticolo,
        rigaModello.DescrizioneVoce,
        rigaModello.IdTipoRiga AS IdTipoRigaAssegnato,
        compatibili.NumeroTipiCompatibili,
        compatibili.TipiCompatibili
    FROM dbo.ModelliPreventivoRighe AS rigaModello
    INNER JOIN dbo.ModelliPreventivo AS modello
        ON modello.IdModelloPreventivo = rigaModello.IdModelloPreventivo
    LEFT JOIN dbo.TipiRigaPreventivo AS tipoAssegnato
        ON tipoAssegnato.IdTipoRiga = rigaModello.IdTipoRiga
    OUTER APPLY
    (
        SELECT
            COUNT(*) AS NumeroTipiCompatibili,
            STRING_AGG(
                CONVERT(NVARCHAR(MAX), CONCAT(tipo.IdTipoRiga, N' - ', tipo.Codice, N' - ', tipo.Descrizione)),
                N'; ') AS TipiCompatibili
        FROM dbo.TipiRigaPreventivo AS tipo
        WHERE tipo.Attiva = 1
          AND
          (
              (rigaModello.IdArticolo IS NOT NULL AND tipo.RigaArticolo = 1)
              OR
              (rigaModello.IdArticolo IS NULL AND tipo.RigaLibera = 1)
          )
    ) AS compatibili
    WHERE rigaModello.IdTipoRiga IS NULL
       OR tipoAssegnato.IdTipoRiga IS NULL
       OR NOT
          (
              (rigaModello.IdArticolo IS NOT NULL AND tipoAssegnato.RigaArticolo = 1)
              OR
              (rigaModello.IdArticolo IS NULL AND tipoAssegnato.RigaLibera = 1)
          )
    ORDER BY modello.CodiceModelloPreventivo, rigaModello.RigaNr;

    THROW 51811, 'TEC-008: classificare le righe modello elencate e rieseguire lo script.', 1;
END;
GO

IF EXISTS
(
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.ModelliPreventivoRighe')
      AND name = N'IdTipoRiga'
      AND is_nullable = 1
)
BEGIN
    ALTER TABLE dbo.ModelliPreventivoRighe
        ALTER COLUMN IdTipoRiga INT NOT NULL;
END;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.foreign_keys
    WHERE parent_object_id = OBJECT_ID(N'dbo.ModelliPreventivoRighe')
      AND name = N'FK_ModelliPreventivoRighe_TipiRigaPreventivo'
)
BEGIN
    ALTER TABLE dbo.ModelliPreventivoRighe WITH CHECK
        ADD CONSTRAINT FK_ModelliPreventivoRighe_TipiRigaPreventivo
        FOREIGN KEY (IdTipoRiga)
        REFERENCES dbo.TipiRigaPreventivo (IdTipoRiga);
END;
GO

ALTER TABLE dbo.ModelliPreventivoRighe WITH CHECK
    CHECK CONSTRAINT FK_ModelliPreventivoRighe_TipiRigaPreventivo;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'dbo.ModelliPreventivoRighe')
      AND name = N'IX_ModelliPreventivoRighe_IdTipoRiga'
)
BEGIN
    CREATE INDEX IX_ModelliPreventivoRighe_IdTipoRiga
        ON dbo.ModelliPreventivoRighe (IdTipoRiga);
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Crea
    @Origine NVARCHAR(20),
    @DataPreventivo DATE,
    @IdCliente INT = NULL,
    @IdRichiestaCliente INT = NULL,
    @IdModelloPreventivo INT = NULL,
    @Oggetto NVARCHAR(250),
    @Note NVARCHAR(MAX) = NULL,
    @MarkupPercDefault DECIMAL(9,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Origine = LTRIM(RTRIM(@Origine));
    SET @Oggetto = NULLIF(LTRIM(RTRIM(@Oggetto)), N'');
    SET @Note = NULLIF(LTRIM(RTRIM(@Note)), N'');

    IF @Origine IS NULL OR @Origine NOT IN (N'Libero', N'Richiesta', N'Modello')
        THROW 51801, 'Origine del preventivo non valida.', 1;

    IF @DataPreventivo IS NULL
        THROW 51802, 'Data del preventivo obbligatoria.', 1;

    IF @MarkupPercDefault IS NULL OR @MarkupPercDefault < 0
        THROW 51803, 'Il markup non puo essere negativo.', 1;

    IF @Origine = N'Richiesta'
       AND NOT EXISTS
       (
           SELECT 1
           FROM dbo.RichiesteClienti
           WHERE IdRichiestaCliente = @IdRichiestaCliente
       )
        THROW 51804, 'Richiesta cliente non trovata.', 1;

    IF @Origine = N'Modello'
       AND NOT EXISTS
       (
           SELECT 1
           FROM dbo.ModelliPreventivo
           WHERE IdModelloPreventivo = @IdModelloPreventivo
             AND Attivo = 1
       )
        THROW 51805, 'Modello preventivo non trovato o non attivo.', 1;

    IF @Origine = N'Richiesta'
    BEGIN
        SELECT
            @IdCliente = richiesta.IdCliente,
            @Oggetto = COALESCE(@Oggetto, richiesta.Oggetto)
        FROM dbo.RichiesteClienti AS richiesta
        WHERE richiesta.IdRichiestaCliente = @IdRichiestaCliente;

        IF @IdCliente IS NULL
           OR NOT EXISTS
           (
               SELECT 1
               FROM dbo.Clienti
               WHERE IdCliente = @IdCliente
                 AND Attivo = 1
           )
            THROW 51810, 'Il cliente collegato alla richiesta non e attivo.', 1;
    END;

    IF @Origine = N'Modello'
    BEGIN
        SELECT
            @IdCliente = COALESCE(@IdCliente, modello.IdCliente),
            @Oggetto = COALESCE(@Oggetto, modello.Oggetto),
            @Note = COALESCE(@Note, modello.Note)
        FROM dbo.ModelliPreventivo AS modello
        WHERE modello.IdModelloPreventivo = @IdModelloPreventivo;
    END;

    IF @Origine = N'Libero' AND @IdCliente IS NULL
        THROW 51806, 'Cliente obbligatorio per il preventivo libero.', 1;

    IF @IdCliente IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1
           FROM dbo.Clienti
           WHERE IdCliente = @IdCliente
             AND Attivo = 1
       )
        THROW 51806, 'Cliente non trovato o non attivo.', 1;

    IF @Oggetto IS NULL
        THROW 51807, 'Oggetto del preventivo obbligatorio.', 1;

    IF @Origine = N'Modello'
       AND EXISTS
       (
           SELECT 1
           FROM dbo.ModelliPreventivoRighe AS rigaModello
           LEFT JOIN dbo.TipiRigaPreventivo AS tipo
               ON tipo.IdTipoRiga = rigaModello.IdTipoRiga
           WHERE rigaModello.IdModelloPreventivo = @IdModelloPreventivo
             AND
             (
                 tipo.IdTipoRiga IS NULL
                 OR tipo.Attiva = 0
                 OR NOT
                    (
                        (rigaModello.IdArticolo IS NOT NULL AND tipo.RigaArticolo = 1)
                        OR
                        (rigaModello.IdArticolo IS NULL AND tipo.RigaLibera = 1)
                    )
             )
       )
        THROW 51809, 'Il modello contiene righe con tipo non valido, non attivo o incoerente.', 1;

    DECLARE @Anno INT = YEAR(@DataPreventivo);
    DECLARE @NumeroPreventivo INT;
    DECLARE @IdPreventivo INT;
    DECLARE @EsitoLock INT;
    DECLARE @RisorsaLock NVARCHAR(255) = CONCAT(N'Preventivi_Numero_', @Anno);

    BEGIN TRY
        BEGIN TRANSACTION;

        EXEC @EsitoLock = sys.sp_getapplock
            @Resource = @RisorsaLock,
            @LockMode = N'Exclusive',
            @LockOwner = N'Transaction',
            @LockTimeout = 10000;

        IF @EsitoLock < 0
            THROW 51808, 'Impossibile assegnare il numero progressivo.', 1;

        SELECT @NumeroPreventivo = ISNULL(MAX(NumeroPreventivo), 0) + 1
        FROM dbo.Preventivi WITH (UPDLOCK, HOLDLOCK)
        WHERE Anno = @Anno;

        INSERT INTO dbo.Preventivi
        (
            NumeroPreventivo,
            Anno,
            DataPreventivo,
            IdCliente,
            IdModelloPreventivo,
            Oggetto,
            Note,
            Stato,
            MarkupPercDefault,
            IdRichiestaCliente
        )
        VALUES
        (
            @NumeroPreventivo,
            @Anno,
            @DataPreventivo,
            @IdCliente,
            CASE WHEN @Origine = N'Modello' THEN @IdModelloPreventivo END,
            @Oggetto,
            @Note,
            N'Bozza',
            @MarkupPercDefault,
            CASE WHEN @Origine = N'Richiesta' THEN @IdRichiestaCliente END
        );

        SET @IdPreventivo = CONVERT(INT, SCOPE_IDENTITY());

        IF @Origine = N'Modello'
        BEGIN
            INSERT INTO dbo.PreventiviRighe
            (
                IdPreventivo,
                RigaNr,
                IdArticolo,
                IdModelloCiclo,
                DescrizioneVoce,
                Quantita,
                PrezzoUnitarioVendita,
                TotaleVendita,
                TotaleCosti,
                MargineValore,
                MarginePerc,
                Note,
                MarkupPerc,
                PrezzoManuale,
                CostoUnitarioLibero,
                IdTipoRiga
            )
            SELECT
                @IdPreventivo,
                rigaModello.RigaNr,
                rigaModello.IdArticolo,
                rigaModello.IdModelloCiclo,
                rigaModello.DescrizioneVoce,
                rigaModello.Quantita,
                rigaModello.PrezzoUnitarioVendita,
                ROUND(rigaModello.Quantita * rigaModello.PrezzoUnitarioVendita, 2),
                CONVERT(DECIMAL(18,2), 0),
                ROUND(rigaModello.Quantita * rigaModello.PrezzoUnitarioVendita, 2),
                CASE
                    WHEN rigaModello.PrezzoUnitarioVendita = 0 THEN CONVERT(DECIMAL(9,2), 0)
                    ELSE CONVERT(DECIMAL(9,2), 100)
                END,
                rigaModello.Note,
                @MarkupPercDefault,
                CONVERT(BIT, 1),
                CASE
                    WHEN tipo.RigaLibera = 1 AND tipo.RigaArticolo = 0
                        THEN CONVERT(DECIMAL(18,4), 0)
                END,
                rigaModello.IdTipoRiga
            FROM dbo.ModelliPreventivoRighe AS rigaModello
            INNER JOIN dbo.TipiRigaPreventivo AS tipo
                ON tipo.IdTipoRiga = rigaModello.IdTipoRiga
               AND tipo.Attiva = 1
            WHERE rigaModello.IdModelloPreventivo = @IdModelloPreventivo;

            EXEC dbo.sp_RicalcolaTotaliPreventivo @IdPreventivo = @IdPreventivo;
        END;

        IF @Origine = N'Richiesta'
        BEGIN
            UPDATE dbo.RichiesteClienti
            SET Stato = N'Preventivata',
                DataAttivazione = ISNULL(DataAttivazione, @DataPreventivo),
                DataModifica = SYSDATETIME()
            WHERE IdRichiestaCliente = @IdRichiestaCliente;
        END;

        COMMIT TRANSACTION;

        SELECT @IdPreventivo;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_CreaPreventivoDaModello
    @IdModelloPreventivo INT,
    @NumeroPreventivo INT,
    @Anno INT,
    @DataPreventivo DATE,
    @IdCliente INT = NULL,
    @Oggetto NVARCHAR(250) = NULL,
    @IdPreventivoCreato INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.ModelliPreventivo
        WHERE IdModelloPreventivo = @IdModelloPreventivo
          AND Attivo = 1
    )
        THROW 51805, 'Modello preventivo non trovato o non attivo.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.ModelliPreventivoRighe AS rigaModello
        LEFT JOIN dbo.TipiRigaPreventivo AS tipo
            ON tipo.IdTipoRiga = rigaModello.IdTipoRiga
        WHERE rigaModello.IdModelloPreventivo = @IdModelloPreventivo
          AND
          (
              tipo.IdTipoRiga IS NULL
              OR tipo.Attiva = 0
              OR NOT
                 (
                     (rigaModello.IdArticolo IS NOT NULL AND tipo.RigaArticolo = 1)
                     OR
                     (rigaModello.IdArticolo IS NULL AND tipo.RigaLibera = 1)
                 )
          )
    )
        THROW 51809, 'Il modello contiene righe con tipo non valido, non attivo o incoerente.', 1;

    INSERT INTO dbo.Preventivi
    (
        NumeroPreventivo,
        Anno,
        DataPreventivo,
        IdCliente,
        IdModelloPreventivo,
        Oggetto,
        Note,
        Stato
    )
    SELECT
        @NumeroPreventivo,
        @Anno,
        @DataPreventivo,
        COALESCE(@IdCliente, modello.IdCliente),
        modello.IdModelloPreventivo,
        COALESCE(@Oggetto, modello.Oggetto),
        modello.Note,
        N'Bozza'
    FROM dbo.ModelliPreventivo AS modello
    WHERE modello.IdModelloPreventivo = @IdModelloPreventivo;

    SET @IdPreventivoCreato = CONVERT(INT, SCOPE_IDENTITY());

    INSERT INTO dbo.PreventiviRighe
    (
        IdPreventivo,
        RigaNr,
        IdArticolo,
        IdModelloCiclo,
        DescrizioneVoce,
        Quantita,
        PrezzoUnitarioVendita,
        TotaleVendita,
        TotaleCosti,
        MargineValore,
        MarginePerc,
        Note,
        CostoUnitarioLibero,
        IdTipoRiga
    )
    SELECT
        @IdPreventivoCreato,
        rigaModello.RigaNr,
        rigaModello.IdArticolo,
        rigaModello.IdModelloCiclo,
        rigaModello.DescrizioneVoce,
        rigaModello.Quantita,
        rigaModello.PrezzoUnitarioVendita,
        CONVERT(DECIMAL(18,2), 0),
        CONVERT(DECIMAL(18,2), 0),
        CONVERT(DECIMAL(18,2), 0),
        CONVERT(DECIMAL(9,2), 0),
        rigaModello.Note,
        CASE
            WHEN tipo.RigaLibera = 1 AND tipo.RigaArticolo = 0
                THEN CONVERT(DECIMAL(18,4), 0)
        END,
        rigaModello.IdTipoRiga
    FROM dbo.ModelliPreventivoRighe AS rigaModello
    INNER JOIN dbo.TipiRigaPreventivo AS tipo
        ON tipo.IdTipoRiga = rigaModello.IdTipoRiga
       AND tipo.Attiva = 1
    WHERE rigaModello.IdModelloPreventivo = @IdModelloPreventivo;

    EXEC dbo.sp_RicalcolaTotaliPreventivo
        @IdPreventivo = @IdPreventivoCreato;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ImportaModelliPreventivoDaStaging
    @BatchId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.ImportModelliPreventivo_Righe AS importRiga
        LEFT JOIN dbo.Articoli AS articolo
            ON articolo.CodiceArticolo = importRiga.CodiceArticolo
        WHERE importRiga.BatchId = @BatchId
          AND NULLIF(LTRIM(RTRIM(importRiga.CodiceArticolo)), N'') IS NOT NULL
          AND articolo.IdArticolo IS NULL
    )
    BEGIN
        SELECT
            importRiga.IdImport,
            importRiga.CodiceModelloPreventivo,
            importRiga.RigaNr,
            importRiga.CodiceArticolo
        FROM dbo.ImportModelliPreventivo_Righe AS importRiga
        LEFT JOIN dbo.Articoli AS articolo
            ON articolo.CodiceArticolo = importRiga.CodiceArticolo
        WHERE importRiga.BatchId = @BatchId
          AND NULLIF(LTRIM(RTRIM(importRiga.CodiceArticolo)), N'') IS NOT NULL
          AND articolo.IdArticolo IS NULL
        ORDER BY importRiga.CodiceModelloPreventivo, importRiga.RigaNr;

        THROW 51813, 'Import modelli: articolo non trovato per le righe elencate.', 1;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.ImportModelliPreventivo_Righe AS importRiga
        LEFT JOIN dbo.ModelliCiclo AS modelloCiclo
            ON modelloCiclo.CodiceModelloCiclo = importRiga.CodiceModelloCiclo
        WHERE importRiga.BatchId = @BatchId
          AND NULLIF(LTRIM(RTRIM(importRiga.CodiceModelloCiclo)), N'') IS NOT NULL
          AND modelloCiclo.IdModelloCiclo IS NULL
    )
    BEGIN
        SELECT
            importRiga.IdImport,
            importRiga.CodiceModelloPreventivo,
            importRiga.RigaNr,
            importRiga.CodiceModelloCiclo
        FROM dbo.ImportModelliPreventivo_Righe AS importRiga
        LEFT JOIN dbo.ModelliCiclo AS modelloCiclo
            ON modelloCiclo.CodiceModelloCiclo = importRiga.CodiceModelloCiclo
        WHERE importRiga.BatchId = @BatchId
          AND NULLIF(LTRIM(RTRIM(importRiga.CodiceModelloCiclo)), N'') IS NOT NULL
          AND modelloCiclo.IdModelloCiclo IS NULL
        ORDER BY importRiga.CodiceModelloPreventivo, importRiga.RigaNr;

        THROW 51814, 'Import modelli: modello ciclo non trovato per le righe elencate.', 1;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.ImportModelliPreventivo_Righe AS importRiga
        LEFT JOIN dbo.Articoli AS articolo
            ON articolo.CodiceArticolo = importRiga.CodiceArticolo
        OUTER APPLY
        (
            SELECT COUNT(*) AS NumeroTipiCompatibili
            FROM dbo.TipiRigaPreventivo AS tipo
            WHERE tipo.Attiva = 1
              AND
              (
                  (articolo.IdArticolo IS NOT NULL AND tipo.RigaArticolo = 1)
                  OR
                  (articolo.IdArticolo IS NULL AND tipo.RigaLibera = 1)
              )
        ) AS compatibili
        WHERE importRiga.BatchId = @BatchId
          AND compatibili.NumeroTipiCompatibili <> 1
    )
    BEGIN
        SELECT
            importRiga.IdImport,
            importRiga.CodiceModelloPreventivo,
            importRiga.RigaNr,
            importRiga.CodiceArticolo,
            importRiga.DescrizioneVoce,
            compatibili.NumeroTipiCompatibili,
            compatibili.TipiCompatibili
        FROM dbo.ImportModelliPreventivo_Righe AS importRiga
        LEFT JOIN dbo.Articoli AS articolo
            ON articolo.CodiceArticolo = importRiga.CodiceArticolo
        OUTER APPLY
        (
            SELECT
                COUNT(*) AS NumeroTipiCompatibili,
                STRING_AGG(
                    CONVERT(NVARCHAR(MAX), CONCAT(tipo.IdTipoRiga, N' - ', tipo.Codice, N' - ', tipo.Descrizione)),
                    N'; ') AS TipiCompatibili
            FROM dbo.TipiRigaPreventivo AS tipo
            WHERE tipo.Attiva = 1
              AND
              (
                  (articolo.IdArticolo IS NOT NULL AND tipo.RigaArticolo = 1)
                  OR
                  (articolo.IdArticolo IS NULL AND tipo.RigaLibera = 1)
              )
        ) AS compatibili
        WHERE importRiga.BatchId = @BatchId
          AND compatibili.NumeroTipiCompatibili <> 1
        ORDER BY importRiga.CodiceModelloPreventivo, importRiga.RigaNr;

        THROW 51812, 'Import modelli: tipo riga assente o ambiguo per le righe elencate.', 1;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        MERGE dbo.ModelliPreventivo AS destinazione
        USING
        (
            SELECT DISTINCT
                importTestata.CodiceModelloPreventivo,
                importTestata.Descrizione,
                cliente.IdCliente,
                importTestata.Oggetto,
                importTestata.Note
            FROM dbo.ImportModelliPreventivo_Testata AS importTestata
            LEFT JOIN dbo.Clienti AS cliente
                ON importTestata.CodiceCliente = cliente.CodiceCliente
            WHERE importTestata.BatchId = @BatchId
        ) AS origine
        ON destinazione.CodiceModelloPreventivo = origine.CodiceModelloPreventivo
        WHEN MATCHED THEN
            UPDATE SET
                destinazione.Descrizione = origine.Descrizione,
                destinazione.IdCliente = origine.IdCliente,
                destinazione.Oggetto = origine.Oggetto,
                destinazione.Note = origine.Note,
                destinazione.DataModifica = SYSDATETIME()
        WHEN NOT MATCHED THEN
            INSERT (CodiceModelloPreventivo, Descrizione, IdCliente, Oggetto, Note)
            VALUES (origine.CodiceModelloPreventivo, origine.Descrizione, origine.IdCliente, origine.Oggetto, origine.Note);

        DELETE rigaModello
        FROM dbo.ModelliPreventivoRighe AS rigaModello
        INNER JOIN dbo.ModelliPreventivo AS modello
            ON rigaModello.IdModelloPreventivo = modello.IdModelloPreventivo
        INNER JOIN dbo.ImportModelliPreventivo_Righe AS importRiga
            ON importRiga.CodiceModelloPreventivo = modello.CodiceModelloPreventivo
           AND importRiga.BatchId = @BatchId;

        INSERT INTO dbo.ModelliPreventivoRighe
        (
            IdModelloPreventivo,
            RigaNr,
            IdArticolo,
            IdModelloCiclo,
            DescrizioneVoce,
            Quantita,
            PrezzoUnitarioVendita,
            Note,
            IdTipoRiga
        )
        SELECT
            modello.IdModelloPreventivo,
            importRiga.RigaNr,
            articolo.IdArticolo,
            modelloCiclo.IdModelloCiclo,
            importRiga.DescrizioneVoce,
            ISNULL(importRiga.Quantita, 1),
            ISNULL(importRiga.PrezzoUnitarioVendita, 0),
            importRiga.Note,
            tipoUnivoco.IdTipoRiga
        FROM dbo.ImportModelliPreventivo_Righe AS importRiga
        INNER JOIN dbo.ModelliPreventivo AS modello
            ON importRiga.CodiceModelloPreventivo = modello.CodiceModelloPreventivo
        LEFT JOIN dbo.Articoli AS articolo
            ON importRiga.CodiceArticolo = articolo.CodiceArticolo
        LEFT JOIN dbo.ModelliCiclo AS modelloCiclo
            ON importRiga.CodiceModelloCiclo = modelloCiclo.CodiceModelloCiclo
        CROSS APPLY
        (
            SELECT MIN(tipo.IdTipoRiga) AS IdTipoRiga
            FROM dbo.TipiRigaPreventivo AS tipo
            WHERE tipo.Attiva = 1
              AND
              (
                  (articolo.IdArticolo IS NOT NULL AND tipo.RigaArticolo = 1)
                  OR
                  (articolo.IdArticolo IS NULL AND tipo.RigaLibera = 1)
              )
            HAVING COUNT(*) = 1
        ) AS tipoUnivoco
        WHERE importRiga.BatchId = @BatchId;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO
