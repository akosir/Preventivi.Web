-- Gestione diretta della distinta corrente. Installare con il pacchetto applicativo completo.
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @Versione INT = 2026111702;
    DECLARE @Codice NVARCHAR(50) = N'TEC-016-DISTINTA-CORRENTE';
    DECLARE @Script NVARCHAR(260) = N'TEC-016_14_Distinta_Corrente.sql';
    DECLARE @Impronta CHAR(64) = 'AF358F4BE44EFFFA60ECD3B221E8E9FE70BEEFE3F07FCBF4751C2C06BA4A12A0';

    IF NOT EXISTS (SELECT 1 FROM dbo.VersioniSchema WITH (UPDLOCK, HOLDLOCK)
                   WHERE Versione = 2026111701 AND CodiceIntervento = N'TEC-016-VERSIONE-CONTENUTO')
        THROW 53903, 'Versione prerequisito 2026111701 non installata.', 1;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione > @Versione)
        THROW 53904, 'Il database contiene una versione successiva.', 1;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione = @Versione
               AND CodiceIntervento = @Codice AND NomeScript = @Script AND ImprontaSha256 = @Impronta)
    BEGIN
        COMMIT TRANSACTION;
        RETURN;
    END;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione = @Versione
               OR CodiceIntervento = @Codice OR NomeScript = @Script)
        THROW 53905, 'Versione gia registrata con metadati differenti.', 1;

/* PAYLOAD TEC-016-DISTINTA-CORRENTE START */
    -- Conserva gli identificativi e i riferimenti delle copie operative.
    UPDATE dbo.DistinteBaseRevisioni SET Stato = N'Superata' WHERE Stato = N'Bozza';

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Lavorazioni_Crea
        @IdNodoDistinta INT, @IdLavorazione INT, @Sequenza INT,
        @TempoSetupMin DECIMAL(18,2), @TempoPezzoMin DECIMAL(18,4),
        @CostoOrario DECIMAL(18,4), @CostoFisso DECIMAL(18,4),
        @Note NVARCHAR(500) = NULL, @Utente NVARCHAR(256),
        @ConsentiAnagraficaNonAttiva BIT = 0
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
            @TempoPezzoMin, @CostoOrario, @CostoFisso, NULL,
            @Note, SYSDATETIME(), NULL, @Utente, NULL
        );
        DECLARE @IdDistintaLavorazione INT = CONVERT(INT, SCOPE_IDENTITY());
        COMMIT TRANSACTION;
        SELECT @IdDistintaLavorazione;
    END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Lavorazioni_Aggiorna
        @IdDistintaLavorazione INT, @IdNodoDistinta INT, @IdLavorazione INT,
        @Sequenza INT, @TempoSetupMin DECIMAL(18,2),
        @TempoPezzoMin DECIMAL(18,4), @CostoOrario DECIMAL(18,4),
        @CostoFisso DECIMAL(18,4), @Note NVARCHAR(500) = NULL,
        @Utente NVARCHAR(256), @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON; SET XACT_ABORT ON;
        SET @Note = NULLIF(LTRIM(RTRIM(@Note)), N'''');
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
        IF @Sequenza <= 0 OR @TempoSetupMin < 0 OR @TempoPezzoMin < 0
           OR @CostoOrario < 0 OR @CostoFisso < 0 OR @Utente IS NULL
            THROW 53601, ''Dati lavorazione non validi.'', 1;
        BEGIN TRANSACTION;
        DECLARE @IdNodoCorrente INT, @IdLavorazioneCorrente INT;
        SELECT @IdNodoCorrente = IdNodoDistinta,
               @IdLavorazioneCorrente = IdLavorazione
        FROM dbo.DistintaLavorazioni WITH (UPDLOCK, HOLDLOCK)
        WHERE IdDistintaLavorazione = @IdDistintaLavorazione;
        IF @IdNodoCorrente IS NULL THROW 53626, ''Riga lavorazione non trovata.'', 1;
        IF @IdNodoCorrente <> @IdNodoDistinta THROW 53615, ''Nodo non modificabile.'', 1;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.DistintaBaseNodi AS nodo
            INNER JOIN dbo.DistinteBaseRevisioni AS revisione
                ON revisione.IdRevisioneDistinta = nodo.IdRevisioneDistinta
            WHERE nodo.IdNodoDistinta = @IdNodoDistinta
              AND revisione.Stato = N''Pubblicata''
        )
            THROW 53606, ''La revisione non e modificabile.'', 1;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.DistintaLavorazioni
            WHERE IdDistintaLavorazione = @IdDistintaLavorazione
              AND VersioneRiga = @VersioneRiga
        )
            THROW 53607, ''Riga modificata da altro utente.'', 1;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.Lavorazioni
            WHERE IdLavorazione = @IdLavorazione
              AND (Attiva = 1 OR IdLavorazione = @IdLavorazioneCorrente)
        )
            THROW 53624, ''Lavorazione non valida.'', 1;
        IF EXISTS
        (
            SELECT 1 FROM dbo.DistintaLavorazioni
            WHERE IdNodoDistinta = @IdNodoDistinta AND Sequenza = @Sequenza
              AND IdDistintaLavorazione <> @IdDistintaLavorazione
        )
            THROW 53625, ''Sequenza gia utilizzata sul nodo.'', 1;
        UPDATE dbo.DistintaLavorazioni
        SET IdLavorazione = @IdLavorazione, Sequenza = @Sequenza,
            TempoSetupMin = @TempoSetupMin, TempoPezzoMin = @TempoPezzoMin,
            CostoOrario = @CostoOrario, CostoFisso = @CostoFisso,
            Note = @Note, DataModifica = SYSDATETIME(), UtenteModifica = @Utente
        WHERE IdDistintaLavorazione = @IdDistintaLavorazione
          AND VersioneRiga = @VersioneRiga;
        IF @@ROWCOUNT = 0 THROW 53607, ''Riga modificata da altro utente.'', 1;
        COMMIT TRANSACTION;
    END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Lavorazioni_Elimina
        @IdDistintaLavorazione INT, @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON; SET XACT_ABORT ON; BEGIN TRANSACTION;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.DistintaLavorazioni AS lavorazione WITH (UPDLOCK, HOLDLOCK)
            INNER JOIN dbo.DistintaBaseNodi AS nodo
                ON nodo.IdNodoDistinta = lavorazione.IdNodoDistinta
            INNER JOIN dbo.DistinteBaseRevisioni AS revisione
                ON revisione.IdRevisioneDistinta = nodo.IdRevisioneDistinta
            WHERE lavorazione.IdDistintaLavorazione = @IdDistintaLavorazione
              AND revisione.Stato = N''Pubblicata''
        )
            THROW 53606, ''Riga non trovata o revisione non modificabile.'', 1;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.DistintaLavorazioni
            WHERE IdDistintaLavorazione = @IdDistintaLavorazione
              AND VersioneRiga = @VersioneRiga
        )
            THROW 53607, ''Riga modificata da altro utente.'', 1;
        IF EXISTS
        (
            SELECT 1 FROM dbo.Allegati
            WHERE Entita = N''DistintaLavorazioni'' AND IdEntita = @IdDistintaLavorazione
        )
            THROW 53610, ''Eliminare prima gli allegati.'', 1;
        DELETE dbo.DistintaLavorazioni
        WHERE IdDistintaLavorazione = @IdDistintaLavorazione
          AND VersioneRiga = @VersioneRiga;
        COMMIT TRANSACTION;
    END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Nodi_Aggiorna
        @IdNodoDistinta INT, @IdArticolo INT, @IdRevisioneDistinta INT,
        @IdNodoPadre INT = NULL, @IdTipoNodo INT,
        @CodiceNodo NVARCHAR(50) = NULL, @DescrizioneNodo NVARCHAR(200),
        @QuantitaBase DECIMAL(18,4), @OrdineVisualizzazione INT,
        @Note NVARCHAR(500) = NULL, @Utente NVARCHAR(256),
        @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON; SET XACT_ABORT ON;
        SET @CodiceNodo = NULLIF(LTRIM(RTRIM(@CodiceNodo)), N'''');
        SET @DescrizioneNodo = NULLIF(LTRIM(RTRIM(@DescrizioneNodo)), N'''');
        SET @Note = NULLIF(LTRIM(RTRIM(@Note)), N'''');
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
        IF @DescrizioneNodo IS NULL OR @QuantitaBase <= 0
           OR @OrdineVisualizzazione < 0 OR @Utente IS NULL
            THROW 53601, ''Dati nodo non validi.'', 1;
        BEGIN TRANSACTION;
        DECLARE @IdArticoloCorrente INT, @IdRevisioneCorrente INT,
                @IdPadreCorrente INT;
        SELECT @IdArticoloCorrente = IdArticolo,
               @IdRevisioneCorrente = IdRevisioneDistinta,
               @IdPadreCorrente = IdNodoPadre
        FROM dbo.DistintaBaseNodi WITH (UPDLOCK, HOLDLOCK)
        WHERE IdNodoDistinta = @IdNodoDistinta;
        IF @IdArticoloCorrente IS NULL THROW 53614, ''Nodo non trovato.'', 1;
        IF @IdArticoloCorrente <> @IdArticolo
           OR @IdRevisioneCorrente <> @IdRevisioneDistinta
            THROW 53615, ''Articolo o revisione del nodo non modificabili.'', 1;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.DistinteBaseRevisioni
            WHERE IdRevisioneDistinta = @IdRevisioneDistinta
              AND Stato = N''Pubblicata''
        )
            THROW 53606, ''La revisione non e una distinta corrente.'', 1;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.DistintaBaseNodi
            WHERE IdNodoDistinta = @IdNodoDistinta
              AND VersioneRiga = @VersioneRiga
        )
            THROW 53607, ''Nodo modificato da altro utente.'', 1;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.TipiNodoDistinta
            WHERE IdTipoNodo = @IdTipoNodo
              AND (Attivo = 1 OR IdTipoNodo = (SELECT IdTipoNodo FROM dbo.DistintaBaseNodi WHERE IdNodoDistinta = @IdNodoDistinta))
        )
            THROW 53611, ''Tipo nodo non valido.'', 1;
        IF @IdNodoPadre = @IdNodoDistinta THROW 53616, ''Ciclo non consentito.'', 1;
        DECLARE @NuovoLivello INT = 0;
        IF @IdNodoPadre IS NULL
        BEGIN
            IF EXISTS
            (
                SELECT 1 FROM dbo.DistintaBaseNodi
                WHERE IdRevisioneDistinta = @IdRevisioneDistinta
                  AND IdNodoPadre IS NULL AND Attivo = 1
                  AND IdNodoDistinta <> @IdNodoDistinta
            )
                THROW 53612, ''Radice attiva gia presente nella revisione.'', 1;
        END
        ELSE
        BEGIN
            SELECT @NuovoLivello = Livello + 1
            FROM dbo.DistintaBaseNodi
            WHERE IdNodoDistinta = @IdNodoPadre
              AND IdRevisioneDistinta = @IdRevisioneDistinta
              AND Attivo = 1;
            IF @NuovoLivello IS NULL OR @NuovoLivello = 0
                THROW 53613, ''Nodo padre non valido o non attivo.'', 1;
            DECLARE @Ciclo BIT = 0;
            ;WITH Discendenti AS
            (
                SELECT IdNodoDistinta FROM dbo.DistintaBaseNodi
                WHERE IdNodoPadre = @IdNodoDistinta
                UNION ALL
                SELECT figlio.IdNodoDistinta
                FROM dbo.DistintaBaseNodi AS figlio
                INNER JOIN Discendenti AS padre
                    ON padre.IdNodoDistinta = figlio.IdNodoPadre
            )
            SELECT @Ciclo = 1
            FROM Discendenti
            WHERE IdNodoDistinta = @IdNodoPadre
            OPTION (MAXRECURSION 32767);
            IF @Ciclo = 1
                THROW 53616, ''Ciclo non consentito.'', 1;
        END;
        DECLARE @DifferenzaLivello INT =
            @NuovoLivello - (SELECT Livello FROM dbo.DistintaBaseNodi WHERE IdNodoDistinta = @IdNodoDistinta);
        UPDATE dbo.DistintaBaseNodi
        SET IdNodoPadre = @IdNodoPadre, IdTipoNodo = @IdTipoNodo,
            CodiceNodo = @CodiceNodo, DescrizioneNodo = @DescrizioneNodo,
            QuantitaBase = @QuantitaBase, Livello = @NuovoLivello,
            OrdineVisualizzazione = @OrdineVisualizzazione, Note = @Note,
            DataModifica = SYSDATETIME(), UtenteModifica = @Utente
        WHERE IdNodoDistinta = @IdNodoDistinta AND VersioneRiga = @VersioneRiga;
        IF @@ROWCOUNT = 0 THROW 53607, ''Nodo modificato da altro utente.'', 1;
        IF @DifferenzaLivello <> 0
        BEGIN
            ;WITH Discendenti AS
            (
                SELECT IdNodoDistinta FROM dbo.DistintaBaseNodi
                WHERE IdNodoPadre = @IdNodoDistinta
                UNION ALL
                SELECT figlio.IdNodoDistinta
                FROM dbo.DistintaBaseNodi AS figlio
                INNER JOIN Discendenti AS padre
                    ON padre.IdNodoDistinta = figlio.IdNodoPadre
            )
            UPDATE nodo
            SET Livello = Livello + @DifferenzaLivello,
                DataModifica = SYSDATETIME(), UtenteModifica = @Utente
            FROM dbo.DistintaBaseNodi AS nodo
            INNER JOIN Discendenti AS discendente
                ON discendente.IdNodoDistinta = nodo.IdNodoDistinta
            OPTION (MAXRECURSION 32767);
        END;
        COMMIT TRANSACTION;
    END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Nodi_ImpostaStato
        @IdNodoDistinta INT, @Attivo BIT, @Utente NVARCHAR(256),
        @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON; SET XACT_ABORT ON;
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
        IF @Utente IS NULL THROW 53601, ''Utente non valido.'', 1;
        BEGIN TRANSACTION;
        DECLARE @IdRevisioneDistinta INT, @IdNodoPadre INT;
        SELECT @IdRevisioneDistinta = IdRevisioneDistinta,
               @IdNodoPadre = IdNodoPadre
        FROM dbo.DistintaBaseNodi WITH (UPDLOCK, HOLDLOCK)
        WHERE IdNodoDistinta = @IdNodoDistinta;
        IF @IdRevisioneDistinta IS NULL THROW 53614, ''Nodo non trovato.'', 1;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.DistinteBaseRevisioni
            WHERE IdRevisioneDistinta = @IdRevisioneDistinta AND Stato = N''Pubblicata''
        )
            THROW 53606, ''La revisione non e una distinta corrente.'', 1;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.DistintaBaseNodi
            WHERE IdNodoDistinta = @IdNodoDistinta AND VersioneRiga = @VersioneRiga
        )
            THROW 53607, ''Nodo modificato da altro utente.'', 1;
        IF @Attivo = 0 AND EXISTS
        (
            SELECT 1 FROM dbo.DistintaBaseNodi
            WHERE IdNodoPadre = @IdNodoDistinta AND Attivo = 1
        )
            THROW 53617, ''Disattivare prima i nodi figli.'', 1;
        IF @Attivo = 1
        BEGIN
            IF @IdNodoPadre IS NOT NULL AND NOT EXISTS
            (
                SELECT 1 FROM dbo.DistintaBaseNodi
                WHERE IdNodoDistinta = @IdNodoPadre AND Attivo = 1
            )
                THROW 53617, ''Il nodo padre non e attivo.'', 1;
            IF @IdNodoPadre IS NULL AND EXISTS
            (
                SELECT 1 FROM dbo.DistintaBaseNodi
                WHERE IdRevisioneDistinta = @IdRevisioneDistinta
                  AND IdNodoPadre IS NULL AND Attivo = 1
                  AND IdNodoDistinta <> @IdNodoDistinta
            )
                THROW 53612, ''Radice attiva gia presente nella revisione.'', 1;
        END;
        UPDATE dbo.DistintaBaseNodi
        SET Attivo = @Attivo, DataModifica = SYSDATETIME(), UtenteModifica = @Utente
        WHERE IdNodoDistinta = @IdNodoDistinta AND VersioneRiga = @VersioneRiga;
        IF @@ROWCOUNT = 0 THROW 53607, ''Nodo modificato da altro utente.'', 1;
        COMMIT TRANSACTION;
    END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Nodi_Elimina
        @IdNodoDistinta INT, @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON; SET XACT_ABORT ON; BEGIN TRANSACTION;
        DECLARE @IdRevisioneDistinta INT;
        SELECT @IdRevisioneDistinta = IdRevisioneDistinta
        FROM dbo.DistintaBaseNodi WITH (UPDLOCK, HOLDLOCK)
        WHERE IdNodoDistinta = @IdNodoDistinta;
        IF @IdRevisioneDistinta IS NULL THROW 53614, ''Nodo non trovato.'', 1;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.DistinteBaseRevisioni
            WHERE IdRevisioneDistinta = @IdRevisioneDistinta AND Stato = N''Pubblicata''
        )
            THROW 53606, ''La revisione non e una distinta corrente.'', 1;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.DistintaBaseNodi
            WHERE IdNodoDistinta = @IdNodoDistinta AND VersioneRiga = @VersioneRiga
        )
            THROW 53607, ''Nodo modificato da altro utente.'', 1;
        IF EXISTS (SELECT 1 FROM dbo.DistintaBaseNodi WHERE IdNodoPadre = @IdNodoDistinta)
           OR EXISTS (SELECT 1 FROM dbo.DistintaMateriali WHERE IdNodoDistinta = @IdNodoDistinta)
           OR EXISTS (SELECT 1 FROM dbo.DistintaLavorazioni WHERE IdNodoDistinta = @IdNodoDistinta)
           OR EXISTS (SELECT 1 FROM dbo.Allegati WHERE Entita = N''DistintaBaseNodi'' AND IdEntita = @IdNodoDistinta)
            THROW 53618, ''Nodo non vuoto o con allegati.'', 1;
        DELETE dbo.DistintaBaseNodi
        WHERE IdNodoDistinta = @IdNodoDistinta AND VersioneRiga = @VersioneRiga;
        COMMIT TRANSACTION;
    END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Materiali_Crea
        @IdNodoDistinta INT, @IdMateriale INT, @Quantita DECIMAL(18,4),
        @CoeffScartoPerc DECIMAL(9,2), @CostoUnitario DECIMAL(18,4),
        @Note NVARCHAR(500) = NULL, @Utente NVARCHAR(256),
        @ConsentiAnagraficaNonAttiva BIT = 0
    AS
    BEGIN
        SET NOCOUNT ON; SET XACT_ABORT ON;
        SET @Note = NULLIF(LTRIM(RTRIM(@Note)), N'''');
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
        IF @Quantita <= 0 OR @CoeffScartoPerc < 0
           OR @CostoUnitario < 0 OR @Utente IS NULL
            THROW 53601, ''Dati materiale non validi.'', 1;
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
            SELECT 1 FROM dbo.Materiali WITH (UPDLOCK, HOLDLOCK)
            WHERE IdMateriale = @IdMateriale
              AND (Attivo = 1 OR @ConsentiAnagraficaNonAttiva = 1)
        )
            THROW 53621, ''Materiale non valido o non attivo.'', 1;
        IF EXISTS
        (
            SELECT 1 FROM dbo.DistintaMateriali WITH (UPDLOCK, HOLDLOCK)
            WHERE IdNodoDistinta = @IdNodoDistinta AND IdMateriale = @IdMateriale
        )
            THROW 53622, ''Materiale gia presente sul nodo.'', 1;
        INSERT dbo.DistintaMateriali
        (
            IdNodoDistinta, IdMateriale, Quantita, CoeffScartoPerc,
            CostoUnitario, Note, DataCreazione, DataModifica,
            UtenteCreazione, UtenteModifica
        )
        VALUES
        (
            @IdNodoDistinta, @IdMateriale, @Quantita, @CoeffScartoPerc,
            @CostoUnitario, @Note, SYSDATETIME(), NULL, @Utente, NULL
        );
        DECLARE @IdDistintaMateriale INT = CONVERT(INT, SCOPE_IDENTITY());
        COMMIT TRANSACTION;
        SELECT @IdDistintaMateriale;
    END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Materiali_Aggiorna
        @IdDistintaMateriale INT, @IdNodoDistinta INT, @IdMateriale INT,
        @Quantita DECIMAL(18,4), @CoeffScartoPerc DECIMAL(9,2),
        @CostoUnitario DECIMAL(18,4), @Note NVARCHAR(500) = NULL,
        @Utente NVARCHAR(256), @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON; SET XACT_ABORT ON;
        SET @Note = NULLIF(LTRIM(RTRIM(@Note)), N'''');
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
        IF @Quantita <= 0 OR @CoeffScartoPerc < 0
           OR @CostoUnitario < 0 OR @Utente IS NULL
            THROW 53601, ''Dati materiale non validi.'', 1;
        BEGIN TRANSACTION;
        DECLARE @IdNodoCorrente INT, @IdMaterialeCorrente INT;
        SELECT @IdNodoCorrente = IdNodoDistinta,
               @IdMaterialeCorrente = IdMateriale
        FROM dbo.DistintaMateriali WITH (UPDLOCK, HOLDLOCK)
        WHERE IdDistintaMateriale = @IdDistintaMateriale;
        IF @IdNodoCorrente IS NULL THROW 53623, ''Riga materiale non trovata.'', 1;
        IF @IdNodoCorrente <> @IdNodoDistinta THROW 53615, ''Nodo non modificabile.'', 1;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.DistintaBaseNodi AS nodo
            INNER JOIN dbo.DistinteBaseRevisioni AS revisione
                ON revisione.IdRevisioneDistinta = nodo.IdRevisioneDistinta
            WHERE nodo.IdNodoDistinta = @IdNodoDistinta
              AND revisione.Stato = N''Pubblicata''
        )
            THROW 53606, ''La revisione non e modificabile.'', 1;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.DistintaMateriali
            WHERE IdDistintaMateriale = @IdDistintaMateriale
              AND VersioneRiga = @VersioneRiga
        )
            THROW 53607, ''Riga modificata da altro utente.'', 1;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.Materiali
            WHERE IdMateriale = @IdMateriale
              AND (Attivo = 1 OR IdMateriale = @IdMaterialeCorrente)
        )
            THROW 53621, ''Materiale non valido.'', 1;
        IF EXISTS
        (
            SELECT 1 FROM dbo.DistintaMateriali
            WHERE IdNodoDistinta = @IdNodoDistinta AND IdMateriale = @IdMateriale
              AND IdDistintaMateriale <> @IdDistintaMateriale
        )
            THROW 53622, ''Materiale gia presente sul nodo.'', 1;
        UPDATE dbo.DistintaMateriali
        SET IdMateriale = @IdMateriale, Quantita = @Quantita,
            CoeffScartoPerc = @CoeffScartoPerc, CostoUnitario = @CostoUnitario,
            Note = @Note, DataModifica = SYSDATETIME(), UtenteModifica = @Utente
        WHERE IdDistintaMateriale = @IdDistintaMateriale
          AND VersioneRiga = @VersioneRiga;
        IF @@ROWCOUNT = 0 THROW 53607, ''Riga modificata da altro utente.'', 1;
        COMMIT TRANSACTION;
    END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Materiali_Elimina
        @IdDistintaMateriale INT, @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON; SET XACT_ABORT ON; BEGIN TRANSACTION;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.DistintaMateriali AS materiale WITH (UPDLOCK, HOLDLOCK)
            INNER JOIN dbo.DistintaBaseNodi AS nodo
                ON nodo.IdNodoDistinta = materiale.IdNodoDistinta
            INNER JOIN dbo.DistinteBaseRevisioni AS revisione
                ON revisione.IdRevisioneDistinta = nodo.IdRevisioneDistinta
            WHERE materiale.IdDistintaMateriale = @IdDistintaMateriale
              AND revisione.Stato = N''Pubblicata''
        )
            THROW 53606, ''Riga non trovata o revisione non modificabile.'', 1;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.DistintaMateriali
            WHERE IdDistintaMateriale = @IdDistintaMateriale
              AND VersioneRiga = @VersioneRiga
        )
            THROW 53607, ''Riga modificata da altro utente.'', 1;
        IF EXISTS
        (
            SELECT 1 FROM dbo.Allegati
            WHERE Entita = N''DistintaMateriali'' AND IdEntita = @IdDistintaMateriale
        )
            THROW 53610, ''Eliminare prima gli allegati.'', 1;
        DELETE dbo.DistintaMateriali
        WHERE IdDistintaMateriale = @IdDistintaMateriale
          AND VersioneRiga = @VersioneRiga;
        COMMIT TRANSACTION;
    END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Revisioni_CreaBozza
        @IdArticolo INT, @Note NVARCHAR(500) = NULL,
        @Utente NVARCHAR(256)
    AS
    BEGIN
        SET NOCOUNT ON; SET XACT_ABORT ON;
        SET @Note = NULLIF(LTRIM(RTRIM(@Note)), N'''');
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
        IF @IdArticolo <= 0 OR @Utente IS NULL
            THROW 53601, ''Dati revisione non validi.'', 1;
        BEGIN TRANSACTION;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.Articoli WITH (UPDLOCK, HOLDLOCK)
            WHERE IdArticolo = @IdArticolo AND Attivo = 1
        )
            THROW 53602, ''Articolo non valido o non attivo.'', 1;
        DECLARE @IdDistintaBase INT;
        SELECT @IdDistintaBase = IdDistintaBase
        FROM dbo.DistinteBase WITH (UPDLOCK, HOLDLOCK)
        WHERE IdArticolo = @IdArticolo;
        IF @IdDistintaBase IS NULL
        BEGIN
            INSERT dbo.DistinteBase
            (
                IdArticolo, DataCreazione, DataModifica,
                UtenteCreazione, UtenteModifica
            )
            VALUES (@IdArticolo, SYSDATETIME(), NULL, @Utente, NULL);
            SET @IdDistintaBase = CONVERT(INT, SCOPE_IDENTITY());
        END;
        IF EXISTS
        (
            SELECT 1 FROM dbo.DistinteBaseRevisioni WITH (UPDLOCK, HOLDLOCK)
            WHERE IdDistintaBase = @IdDistintaBase AND Stato = N''Pubblicata''
        )
            THROW 53603, ''Esiste gia una distinta corrente.'', 1;
        DECLARE @NumeroRevisione INT =
            COALESCE((SELECT MAX(NumeroRevisione) FROM dbo.DistinteBaseRevisioni WITH (UPDLOCK, HOLDLOCK) WHERE IdDistintaBase = @IdDistintaBase), 0) + 1;
        INSERT dbo.DistinteBaseRevisioni
        (
            IdDistintaBase, NumeroRevisione, Stato, Note,
            DataPubblicazione, DataCreazione, DataModifica,
            UtenteCreazione, UtenteModifica
        )
        VALUES
        (
            @IdDistintaBase, @NumeroRevisione, N''Pubblicata'', @Note,
            NULL, SYSDATETIME(), NULL, @Utente, NULL
        );
        DECLARE @IdRevisioneDistinta INT = CONVERT(INT, SCOPE_IDENTITY());
        COMMIT TRANSACTION;
        SELECT @IdRevisioneDistinta;
    END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Nodi_Crea
        @IdArticolo INT, @IdRevisioneDistinta INT,
        @IdNodoPadre INT = NULL, @IdTipoNodo INT,
        @CodiceNodo NVARCHAR(50) = NULL, @DescrizioneNodo NVARCHAR(200),
        @QuantitaBase DECIMAL(18,4), @OrdineVisualizzazione INT,
        @Note NVARCHAR(500) = NULL, @Utente NVARCHAR(256),
        @ConsentiTipoNodoNonAttivo BIT = 0,
        @IdNodoRevisioneOrigine INT = NULL
    AS
    BEGIN
        SET NOCOUNT ON; SET XACT_ABORT ON;
        SET @CodiceNodo = NULLIF(LTRIM(RTRIM(@CodiceNodo)), N'''');
        SET @DescrizioneNodo = NULLIF(LTRIM(RTRIM(@DescrizioneNodo)), N'''');
        SET @Note = NULLIF(LTRIM(RTRIM(@Note)), N'''');
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
        IF @DescrizioneNodo IS NULL OR @QuantitaBase <= 0
           OR @OrdineVisualizzazione < 0 OR @Utente IS NULL
            THROW 53601, ''Dati nodo non validi.'', 1;
        BEGIN TRANSACTION;
        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.DistinteBaseRevisioni AS revisione WITH (UPDLOCK, HOLDLOCK)
            INNER JOIN dbo.DistinteBase AS distinta
                ON distinta.IdDistintaBase = revisione.IdDistintaBase
            WHERE revisione.IdRevisioneDistinta = @IdRevisioneDistinta
              AND distinta.IdArticolo = @IdArticolo
              AND revisione.Stato = N''Pubblicata''
        )
            THROW 53606, ''La revisione non e una distinta corrente.'', 1;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.TipiNodoDistinta
            WHERE IdTipoNodo = @IdTipoNodo
              AND (Attivo = 1 OR @ConsentiTipoNodoNonAttivo = 1)
        )
            THROW 53611, ''Tipo nodo non valido o non attivo.'', 1;
        DECLARE @Livello INT = 0;
        IF @IdNodoPadre IS NULL
        BEGIN
            IF EXISTS
            (
                SELECT 1 FROM dbo.DistintaBaseNodi WITH (UPDLOCK, HOLDLOCK)
                WHERE IdRevisioneDistinta = @IdRevisioneDistinta
                  AND IdNodoPadre IS NULL AND Attivo = 1
            )
                THROW 53612, ''Radice attiva gia presente nella revisione.'', 1;
        END
        ELSE
        BEGIN
            SELECT @Livello = Livello + 1
            FROM dbo.DistintaBaseNodi WITH (UPDLOCK, HOLDLOCK)
            WHERE IdNodoDistinta = @IdNodoPadre
              AND IdRevisioneDistinta = @IdRevisioneDistinta
              AND Attivo = 1;
            IF @Livello IS NULL OR @Livello = 0
                THROW 53613, ''Nodo padre non valido o non attivo.'', 1;
        END;
        DECLARE @ChiaveContinuita UNIQUEIDENTIFIER = NEWID();
        IF @IdNodoRevisioneOrigine IS NOT NULL
        BEGIN
            SELECT @ChiaveContinuita = origine.ChiaveContinuita
            FROM dbo.DistintaBaseNodi AS origine
            WHERE origine.IdNodoDistinta = @IdNodoRevisioneOrigine
              AND origine.IdArticolo = @IdArticolo
              AND origine.IdRevisioneDistinta <> @IdRevisioneDistinta;
            IF @@ROWCOUNT <> 1
                THROW 53615, ''Nodo di origine non valido per la nuova revisione.'', 1;
        END;
        INSERT dbo.DistintaBaseNodi
        (
            IdArticolo, IdRevisioneDistinta, IdNodoPadre, IdTipoNodo,
            CodiceNodo, DescrizioneNodo, QuantitaBase, Livello,
            OrdineVisualizzazione, Attivo, Note, DataCreazione,
            DataModifica, UtenteCreazione, UtenteModifica, ChiaveContinuita
        )
        VALUES
        (
            @IdArticolo, @IdRevisioneDistinta, @IdNodoPadre, @IdTipoNodo,
            @CodiceNodo, @DescrizioneNodo, @QuantitaBase, @Livello,
            @OrdineVisualizzazione, 1, @Note, SYSDATETIME(),
            NULL, @Utente, NULL, @ChiaveContinuita
        );
        DECLARE @IdNodoDistinta INT = CONVERT(INT, SCOPE_IDENTITY());
        COMMIT TRANSACTION;
        SELECT @IdNodoDistinta;
    END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Importazioni_Applica
        @IdImportazione UNIQUEIDENTIFIER,
        @IdRevisioneDistinta INT,
        @NomeFile NVARCHAR(260),
        @ImprontaSha256 CHAR(64),
        @Utente NVARCHAR(256),
        @VersioneRiga BINARY(8),
        @Nodi dbo.TVP_DistintaImportazioneNodi READONLY,
        @Materiali dbo.TVP_DistintaImportazioneMateriali READONLY,
        @Lavorazioni dbo.TVP_DistintaImportazioneLavorazioni READONLY
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;

        SELECT @NomeFile = NULLIF(LTRIM(RTRIM(@NomeFile)), N''''),
            @ImprontaSha256 = UPPER(NULLIF(LTRIM(RTRIM(@ImprontaSha256)), N'''')),
            @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');

        IF @IdImportazione IS NULL OR @IdRevisioneDistinta <= 0
           OR @NomeFile IS NULL OR LEN(@NomeFile) > 260
           OR @ImprontaSha256 IS NULL OR LEN(@ImprontaSha256) <> 64
           OR @ImprontaSha256 LIKE ''%[^0-9A-F]%''
           OR @Utente IS NULL OR DATALENGTH(@VersioneRiga) <> 8
           OR NOT EXISTS (SELECT 1 FROM @Nodi)
            THROW 53701, ''Dati importazione non validi.'', 1;

        BEGIN TRANSACTION;

        DECLARE @IdArticolo INT;
        SELECT @IdArticolo = distinta.IdArticolo
        FROM dbo.DistinteBaseRevisioni AS revisione WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN dbo.DistinteBase AS distinta
            ON distinta.IdDistintaBase = revisione.IdDistintaBase
        WHERE revisione.IdRevisioneDistinta = @IdRevisioneDistinta
          AND revisione.Stato = N''Pubblicata'';

        IF @IdArticolo IS NULL
            THROW 53702, ''Revisione non trovata o non modificabile.'', 1;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.DistinteBaseRevisioni
            WHERE IdRevisioneDistinta = @IdRevisioneDistinta
              AND VersioneRiga = @VersioneRiga
        )
            THROW 53703, ''Revisione modificata da altro utente.'', 1;
        IF EXISTS
        (
            SELECT 1 FROM dbo.DistintaBaseNodi WITH (UPDLOCK, HOLDLOCK)
            WHERE IdRevisioneDistinta = @IdRevisioneDistinta
        )
            THROW 53704, ''La distinta deve essere vuota.'', 1;
        IF EXISTS
        (
            SELECT 1 FROM dbo.DistinteBaseImportazioni WITH (UPDLOCK, HOLDLOCK)
            WHERE IdRevisioneDistinta = @IdRevisioneDistinta
              AND ImprontaSha256 = @ImprontaSha256
        )
            THROW 53705, ''File gia importato nella revisione.'', 1;

        IF (SELECT COUNT(*) FROM @Nodi WHERE ChiavePadre IS NULL) <> 1
           OR EXISTS (SELECT 1 FROM @Nodi WHERE ChiavePadre IS NULL AND Attivo = 0)
           OR EXISTS (SELECT ChiaveNodo FROM @Nodi GROUP BY ChiaveNodo HAVING COUNT(*) > 1)
           OR EXISTS
              (
                  SELECT 1 FROM @Nodi AS figlio
                  LEFT JOIN @Nodi AS padre ON padre.ChiaveNodo = figlio.ChiavePadre
                  WHERE figlio.ChiavePadre IS NOT NULL
                    AND (padre.ChiaveNodo IS NULL OR figlio.ChiaveNodo = figlio.ChiavePadre)
              )
           OR EXISTS
              (
                  SELECT 1 FROM @Nodi AS figlio
                  INNER JOIN @Nodi AS padre ON padre.ChiaveNodo = figlio.ChiavePadre
                  WHERE figlio.Attivo = 1 AND padre.Attivo = 0
              )
            THROW 53706, ''Gerarchia dei nodi non valida.'', 1;

        DECLARE @NodiRaggiunti INT;
        ;WITH Albero AS
        (
            SELECT ChiaveNodo
            FROM @Nodi WHERE ChiavePadre IS NULL
            UNION ALL
            SELECT figlio.ChiaveNodo
            FROM @Nodi AS figlio
            INNER JOIN Albero AS padre ON padre.ChiaveNodo = figlio.ChiavePadre
        )
        SELECT @NodiRaggiunti = COUNT(*) FROM Albero OPTION (MAXRECURSION 32767);
        IF @NodiRaggiunti <> (SELECT COUNT(*) FROM @Nodi)
            THROW 53706, ''Gerarchia ciclica o non raggiungibile dalla radice.'', 1;

        IF EXISTS
        (
            SELECT 1 FROM @Nodi AS sorgente
            WHERE
            (
                SELECT COUNT(*) FROM dbo.TipiNodoDistinta AS tipo
                WHERE tipo.Descrizione = sorgente.TipoNodo AND tipo.Attivo = 1
            ) <> 1
        )
           OR EXISTS
              (
                  SELECT 1 FROM @Materiali AS sorgente
                  WHERE
                  (
                      SELECT COUNT(*) FROM dbo.Materiali AS materiale
                      WHERE materiale.CodiceMateriale = sorgente.CodiceMateriale
                        AND materiale.Attivo = 1
                  ) <> 1
              )
           OR EXISTS
              (
                  SELECT 1 FROM @Lavorazioni AS sorgente
                  WHERE
                  (
                      SELECT COUNT(*) FROM dbo.Lavorazioni AS lavorazione
                      WHERE lavorazione.CodiceLavorazione = sorgente.CodiceLavorazione
                        AND lavorazione.Attiva = 1
                  ) <> 1
              )
            THROW 53707, ''Anagrafiche non valide o non attive.'', 1;

        IF EXISTS
        (
            SELECT 1 FROM @Nodi
            WHERE QuantitaBase <= 0 OR OrdineVisualizzazione < 0
        )
           OR EXISTS
              (
                  SELECT 1 FROM @Materiali AS materiale
                  LEFT JOIN @Nodi AS nodo ON nodo.ChiaveNodo = materiale.ChiaveNodo
                  WHERE nodo.ChiaveNodo IS NULL OR materiale.Quantita <= 0
                     OR materiale.CoeffScartoPerc < 0 OR materiale.CostoUnitario < 0
              )
           OR EXISTS
              (
                  SELECT ChiaveNodo, CodiceMateriale FROM @Materiali
                  GROUP BY ChiaveNodo, CodiceMateriale HAVING COUNT(*) > 1
              )
           OR EXISTS
              (
                  SELECT 1 FROM @Lavorazioni AS lavorazione
                  LEFT JOIN @Nodi AS nodo ON nodo.ChiaveNodo = lavorazione.ChiaveNodo
                  WHERE nodo.ChiaveNodo IS NULL OR lavorazione.Sequenza <= 0
                     OR lavorazione.TempoSetupMin < 0 OR lavorazione.TempoPezzoMin < 0
                     OR lavorazione.CostoOrario < 0 OR lavorazione.CostoFisso < 0
              )
           OR EXISTS
              (
                  SELECT ChiaveNodo, Sequenza FROM @Lavorazioni
                  GROUP BY ChiaveNodo, Sequenza HAVING COUNT(*) > 1
              )
            THROW 53708, ''Valori o riferimenti del file non validi.'', 1;

        DECLARE @Mappa TABLE
        (
            ChiaveNodo NVARCHAR(50) NOT NULL PRIMARY KEY,
            IdNodoDistinta INT NOT NULL
        );
        DECLARE @Livelli TABLE
        (
            ChiaveNodo NVARCHAR(50) NOT NULL PRIMARY KEY,
            Livello INT NOT NULL
        );

        ;WITH AlberoLivelli AS
        (
            SELECT ChiaveNodo, 0 AS Livello
            FROM @Nodi WHERE ChiavePadre IS NULL
            UNION ALL
            SELECT figlio.ChiaveNodo, padre.Livello + 1
            FROM @Nodi AS figlio
            INNER JOIN AlberoLivelli AS padre ON padre.ChiaveNodo = figlio.ChiavePadre
        )
        INSERT @Livelli (ChiaveNodo, Livello)
        SELECT ChiaveNodo, Livello FROM AlberoLivelli OPTION (MAXRECURSION 32767);

        DECLARE @LivelloCorrente INT = 0,
                @LivelloMassimo INT = (SELECT MAX(Livello) FROM @Livelli);
        WHILE @LivelloCorrente <= @LivelloMassimo
        BEGIN
            MERGE dbo.DistintaBaseNodi AS destinazione
            USING
            (
                SELECT nodo.*, livello.Livello, tipo.IdTipoNodo,
                       padre.IdNodoDistinta AS IdNodoPadre
                FROM @Nodi AS nodo
                INNER JOIN @Livelli AS livello ON livello.ChiaveNodo = nodo.ChiaveNodo
                INNER JOIN dbo.TipiNodoDistinta AS tipo
                    ON tipo.Descrizione = nodo.TipoNodo AND tipo.Attivo = 1
                LEFT JOIN @Mappa AS padre ON padre.ChiaveNodo = nodo.ChiavePadre
                WHERE livello.Livello = @LivelloCorrente
            ) AS sorgente ON 1 = 0
            WHEN NOT MATCHED THEN
                INSERT
                (
                    IdArticolo, IdRevisioneDistinta, IdNodoPadre, IdTipoNodo,
                    CodiceNodo, DescrizioneNodo, QuantitaBase, Livello,
                    OrdineVisualizzazione, Attivo, Note, DataCreazione,
                    DataModifica, UtenteCreazione, UtenteModifica
                )
                VALUES
                (
                    @IdArticolo, @IdRevisioneDistinta, sorgente.IdNodoPadre,
                    sorgente.IdTipoNodo, sorgente.CodiceNodo,
                    sorgente.DescrizioneNodo, sorgente.QuantitaBase,
                    sorgente.Livello, sorgente.OrdineVisualizzazione,
                    sorgente.Attivo, sorgente.Note, SYSDATETIME(), NULL,
                    @Utente, NULL
                )
            OUTPUT sorgente.ChiaveNodo, inserted.IdNodoDistinta
                INTO @Mappa (ChiaveNodo, IdNodoDistinta);
            SET @LivelloCorrente += 1;
        END;

        INSERT dbo.DistintaMateriali
        (
            IdNodoDistinta, IdMateriale, Quantita, CoeffScartoPerc,
            CostoUnitario, Note, DataCreazione, DataModifica,
            UtenteCreazione, UtenteModifica
        )
        SELECT mappa.IdNodoDistinta, materiale.IdMateriale,
               sorgente.Quantita, sorgente.CoeffScartoPerc,
               sorgente.CostoUnitario, sorgente.Note,
               SYSDATETIME(), NULL, @Utente, NULL
        FROM @Materiali AS sorgente
        INNER JOIN @Mappa AS mappa ON mappa.ChiaveNodo = sorgente.ChiaveNodo
        INNER JOIN dbo.Materiali AS materiale
            ON materiale.CodiceMateriale = sorgente.CodiceMateriale
           AND materiale.Attivo = 1;

        INSERT dbo.DistintaLavorazioni
        (
            IdNodoDistinta, IdLavorazione, Sequenza, TempoSetupMin,
            TempoPezzoMin, CostoOrario, CostoFisso, IdModelloCiclo,
            Note, DataCreazione, DataModifica, UtenteCreazione, UtenteModifica
        )
        SELECT mappa.IdNodoDistinta, lavorazione.IdLavorazione,
               sorgente.Sequenza, sorgente.TempoSetupMin,
               sorgente.TempoPezzoMin, sorgente.CostoOrario,
               sorgente.CostoFisso, NULL, sorgente.Note,
               SYSDATETIME(), NULL, @Utente, NULL
        FROM @Lavorazioni AS sorgente
        INNER JOIN @Mappa AS mappa ON mappa.ChiaveNodo = sorgente.ChiaveNodo
        INNER JOIN dbo.Lavorazioni AS lavorazione
            ON lavorazione.CodiceLavorazione = sorgente.CodiceLavorazione
           AND lavorazione.Attiva = 1;

        INSERT dbo.DistinteBaseImportazioni
        (
            IdImportazione, IdRevisioneDistinta, NomeFile,
            ImprontaSha256, NumeroNodi, NumeroMateriali,
            NumeroLavorazioni, DataImportazione, Utente
        )
        VALUES
        (
            @IdImportazione, @IdRevisioneDistinta, @NomeFile,
            @ImprontaSha256, (SELECT COUNT(*) FROM @Nodi),
            (SELECT COUNT(*) FROM @Materiali),
            (SELECT COUNT(*) FROM @Lavorazioni), SYSDATETIME(), @Utente
        );

        UPDATE dbo.DistinteBaseRevisioni
        SET DataModifica = SYSDATETIME(), UtenteModifica = @Utente
        WHERE IdRevisioneDistinta = @IdRevisioneDistinta
          AND VersioneRiga = @VersioneRiga;
        IF @@ROWCOUNT <> 1
            THROW 53703, ''Revisione modificata durante l importazione.'', 1;

        COMMIT TRANSACTION;
    END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Revisioni_Pubblica
        @IdRevisioneDistinta INT, @Motivazione NVARCHAR(500), @Utente NVARCHAR(256), @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON;
        THROW 53606, ''La distinta corrente viene modificata direttamente.'', 1;
    END;';
/* PAYLOAD TEC-016-DISTINTA-CORRENTE END */

    INSERT dbo.VersioniSchema (Versione, CodiceIntervento, NomeScript, Descrizione, ImprontaSha256)
    VALUES (@Versione, @Codice, @Script, N'Gestione diretta della distinta corrente per articolo.', @Impronta);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
