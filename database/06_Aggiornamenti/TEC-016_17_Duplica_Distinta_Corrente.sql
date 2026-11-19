-- Ripristino della duplicazione della distinta corrente su altro articolo.
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @Versione INT = 2026111901;
    DECLARE @Codice NVARCHAR(50) = N'TEC-016-DUPLICA-CORRENTE';
    DECLARE @Script NVARCHAR(260) = N'TEC-016_17_Duplica_Distinta_Corrente.sql';
    DECLARE @Impronta CHAR(64) = 'BEE0A9A0E5A4764E9D9D1E0AC5FCB11945A18B38127615F7206F37CE270F3D9E';
    IF NOT EXISTS (SELECT 1 FROM dbo.VersioniSchema WITH (UPDLOCK, HOLDLOCK)
                   WHERE Versione = 2026111802 AND CodiceIntervento = N'TEC-016-AGGIORNA-DISTINTA')
        THROW 53896, 'Versione prerequisito 2026111802 non installata.', 1;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione > @Versione)
        THROW 53897, 'Il database contiene una versione successiva.', 1;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione = @Versione
               AND CodiceIntervento = @Codice AND NomeScript = @Script AND ImprontaSha256 = @Impronta)
    BEGIN
        COMMIT TRANSACTION;
        RETURN;
    END;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione = @Versione
               OR CodiceIntervento = @Codice OR NomeScript = @Script)
        THROW 53898, 'Versione gia registrata con metadati differenti.', 1;

/* PAYLOAD TEC-016-DUPLICA-CORRENTE START */
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_CompensaDuplicazione
        @IdRevisioneDistinta INT
    AS
    BEGIN
        SET NOCOUNT ON; SET XACT_ABORT ON; BEGIN TRANSACTION;
        DECLARE @IdDistintaBase INT, @Stato NVARCHAR(20);
        SELECT @IdDistintaBase = IdDistintaBase, @Stato = Stato
        FROM dbo.DistinteBaseRevisioni WITH (UPDLOCK, HOLDLOCK)
        WHERE IdRevisioneDistinta = @IdRevisioneDistinta;
        IF @IdDistintaBase IS NULL THROW 53605, ''Revisione non trovata.'', 1;
        IF @Stato <> N''Pubblicata'' THROW 53609, ''La destinazione non e una distinta corrente.'', 1;
        IF EXISTS (SELECT 1 FROM dbo.PreventiviRigheComponenti WITH (UPDLOCK, HOLDLOCK)
                   WHERE IdRevisioneDistintaSnapshot = @IdRevisioneDistinta)
           OR EXISTS (SELECT 1 FROM dbo.DistinteBaseImportazioni WITH (UPDLOCK, HOLDLOCK)
                      WHERE IdRevisioneDistinta = @IdRevisioneDistinta)
            THROW 53609, ''La distinta e utilizzata e richiede un controllo amministrativo.'', 1;
        IF EXISTS
        (
            SELECT 1 FROM dbo.Allegati AS allegato
            WHERE (allegato.Entita = N''DistintaBaseNodi'' AND EXISTS
                  (SELECT 1 FROM dbo.DistintaBaseNodi AS nodo WHERE nodo.IdRevisioneDistinta = @IdRevisioneDistinta AND nodo.IdNodoDistinta = allegato.IdEntita))
               OR (allegato.Entita = N''DistintaMateriali'' AND EXISTS
                  (SELECT 1 FROM dbo.DistintaMateriali AS materiale INNER JOIN dbo.DistintaBaseNodi AS nodo ON nodo.IdNodoDistinta = materiale.IdNodoDistinta WHERE nodo.IdRevisioneDistinta = @IdRevisioneDistinta AND materiale.IdDistintaMateriale = allegato.IdEntita))
               OR (allegato.Entita = N''DistintaLavorazioni'' AND EXISTS
                  (SELECT 1 FROM dbo.DistintaLavorazioni AS lavorazione INNER JOIN dbo.DistintaBaseNodi AS nodo ON nodo.IdNodoDistinta = lavorazione.IdNodoDistinta WHERE nodo.IdRevisioneDistinta = @IdRevisioneDistinta AND lavorazione.IdDistintaLavorazione = allegato.IdEntita))
        )
            THROW 53610, ''La distinta contiene ancora allegati.'', 1;
        DELETE lavorazione
        FROM dbo.DistintaLavorazioni AS lavorazione
        INNER JOIN dbo.DistintaBaseNodi AS nodo
            ON nodo.IdNodoDistinta = lavorazione.IdNodoDistinta
        WHERE nodo.IdRevisioneDistinta = @IdRevisioneDistinta;
        DELETE materiale
        FROM dbo.DistintaMateriali AS materiale
        INNER JOIN dbo.DistintaBaseNodi AS nodo
            ON nodo.IdNodoDistinta = materiale.IdNodoDistinta
        WHERE nodo.IdRevisioneDistinta = @IdRevisioneDistinta;
        DELETE dbo.DistintaBaseNodi WHERE IdRevisioneDistinta = @IdRevisioneDistinta;
        DELETE dbo.DistinteBaseRevisioni WHERE IdRevisioneDistinta = @IdRevisioneDistinta;
        IF NOT EXISTS (SELECT 1 FROM dbo.DistinteBaseRevisioni WHERE IdDistintaBase = @IdDistintaBase)
            DELETE dbo.DistinteBase WHERE IdDistintaBase = @IdDistintaBase;
        COMMIT TRANSACTION;
    END;';
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Lavorazioni_Crea
        @IdNodoDistinta INT, @IdLavorazione INT, @Sequenza INT,
        @TempoSetupMin DECIMAL(18,2), @TempoPezzoMin DECIMAL(18,4),
        @CostoOrario DECIMAL(18,4), @CostoFisso DECIMAL(18,4),
        @Note NVARCHAR(500) = NULL, @Utente NVARCHAR(256),
        @ConsentiAnagraficaNonAttiva BIT = 0,
        @IdModelloCiclo INT = NULL
    AS
    BEGIN
        SET NOCOUNT ON; SET XACT_ABORT ON;
        SET @Note = NULLIF(LTRIM(RTRIM(@Note)), N'''');
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
        IF @Sequenza <= 0 OR @TempoSetupMin < 0 OR @TempoPezzoMin < 0
           OR @CostoOrario < 0 OR @CostoFisso < 0 OR @Utente IS NULL
            THROW 53601, ''Dati lavorazione non validi.'', 1;
        BEGIN TRANSACTION;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.DistintaBaseNodi AS nodo WITH (UPDLOCK, HOLDLOCK)
            INNER JOIN dbo.DistinteBaseRevisioni AS revisione
                ON revisione.IdRevisioneDistinta = nodo.IdRevisioneDistinta
            WHERE nodo.IdNodoDistinta = @IdNodoDistinta
              AND nodo.Attivo = 1 AND revisione.Stato = N''Pubblicata''
        )
            THROW 53606, ''Nodo non valido o revisione non modificabile.'', 1;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.Lavorazioni WITH (UPDLOCK, HOLDLOCK)
            WHERE IdLavorazione = @IdLavorazione
              AND (Attiva = 1 OR @ConsentiAnagraficaNonAttiva = 1)
        )
            THROW 53624, ''Lavorazione non valida o non attiva.'', 1;
        IF EXISTS
        (
            SELECT 1 FROM dbo.DistintaLavorazioni WITH (UPDLOCK, HOLDLOCK)
            WHERE IdNodoDistinta = @IdNodoDistinta AND Sequenza = @Sequenza
        )
            THROW 53625, ''Sequenza gia utilizzata sul nodo.'', 1;
        INSERT dbo.DistintaLavorazioni
        (
            IdNodoDistinta, IdLavorazione, Sequenza, TempoSetupMin,
            TempoPezzoMin, CostoOrario, CostoFisso, IdModelloCiclo,
            Note, DataCreazione, DataModifica, UtenteCreazione, UtenteModifica
        )
        VALUES
        (
            @IdNodoDistinta, @IdLavorazione, @Sequenza, @TempoSetupMin,
            @TempoPezzoMin, @CostoOrario, @CostoFisso, @IdModelloCiclo,
            @Note, SYSDATETIME(), NULL, @Utente, NULL
        );
        DECLARE @IdDistintaLavorazione INT = CONVERT(INT, SCOPE_IDENTITY());
        COMMIT TRANSACTION;
        SELECT @IdDistintaLavorazione;
    END;';
/* PAYLOAD TEC-016-DUPLICA-CORRENTE END */

    INSERT dbo.VersioniSchema (Versione, CodiceIntervento, NomeScript, Descrizione, ImprontaSha256)
    VALUES (@Versione, @Codice, @Script, N'Duplicazione della distinta corrente con compensazione controllata.', @Impronta);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
