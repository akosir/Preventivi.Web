/*
    TEC-008 - Regole riga articolo nella creazione da modello

    Il costo libero viene inizializzato soltanto per un tipo libero che non e
    una riga articolo. Il tipo resta quello memorizzato nella riga modello.

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

IF OBJECT_ID(N'dbo.Preventivi', N'U') IS NULL
   OR OBJECT_ID(N'dbo.PreventiviRighe', N'U') IS NULL
   OR OBJECT_ID(N'dbo.Clienti', N'U') IS NULL
   OR OBJECT_ID(N'dbo.RichiesteClienti', N'U') IS NULL
   OR OBJECT_ID(N'dbo.ModelliPreventivo', N'U') IS NULL
   OR OBJECT_ID(N'dbo.ModelliPreventivoRighe', N'U') IS NULL
   OR OBJECT_ID(N'dbo.TipiRigaPreventivo', N'U') IS NULL
   OR OBJECT_ID(N'dbo.sp_RicalcolaTotaliPreventivo', N'P') IS NULL
BEGIN
    THROW 51800, 'TEC-008: schema richiesto non disponibile.', 1;
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
