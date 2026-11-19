/*
    TEC-016 - Revisioni e duplicazione completa delle distinte base
    Versione schema: 2026111202
    Prerequisito: 2026111201 (TEC-016-MODELLI-CICLO).

    Eseguire sul database Preventivi dell'ambiente di destinazione dopo una
    copia di sicurezza verificata. Lo script non contiene USE.
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;

BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID(N'dbo.VersioniSchema', N'U') IS NULL
        THROW 53690, 'TEC-016-REVISIONI: registro VersioniSchema non disponibile.', 1;

    IF NOT EXISTS
    (
        SELECT 1 FROM dbo.VersioniSchema
        WHERE Versione = 2026111201
          AND CodiceIntervento = N'TEC-016-MODELLI-CICLO'
    )
        THROW 53691, 'TEC-016-REVISIONI: versione richiesta 2026111201 non installata.', 1;

    IF EXISTS
    (
        SELECT 1 FROM dbo.VersioniSchema
        WHERE Versione > 2026111201
          AND Versione <> 2026111202
    )
        THROW 53692, 'TEC-016-REVISIONI: il database contiene una versione successiva non riconosciuta.', 1;

    IF OBJECT_ID(N'dbo.DistintaBaseNodi', N'U') IS NULL
       OR OBJECT_ID(N'dbo.DistintaMateriali', N'U') IS NULL
       OR OBJECT_ID(N'dbo.DistintaLavorazioni', N'U') IS NULL
       OR OBJECT_ID(N'dbo.Articoli', N'U') IS NULL
       OR OBJECT_ID(N'dbo.Allegati', N'U') IS NULL
        THROW 53693, 'TEC-016-REVISIONI: tabelle richieste non disponibili.', 1;

    /* PAYLOAD TEC-016-DISTINTE-REVISIONI START */
    IF OBJECT_ID(N'dbo.DistinteBase', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.DistinteBase
        (
            IdDistintaBase INT IDENTITY(1,1) NOT NULL
                CONSTRAINT PK_DistinteBase PRIMARY KEY,
            IdArticolo INT NOT NULL,
            DataCreazione DATETIME2(0) NOT NULL,
            DataModifica DATETIME2(0) NULL,
            UtenteCreazione NVARCHAR(256) NOT NULL,
            UtenteModifica NVARCHAR(256) NULL,
            VersioneRiga ROWVERSION NOT NULL,
            CONSTRAINT UQ_DistinteBase_IdArticolo UNIQUE (IdArticolo),
            CONSTRAINT FK_DistinteBase_Articoli FOREIGN KEY (IdArticolo)
                REFERENCES dbo.Articoli(IdArticolo)
        );
    END;

    IF OBJECT_ID(N'dbo.DistinteBaseRevisioni', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.DistinteBaseRevisioni
        (
            IdRevisioneDistinta INT IDENTITY(1,1) NOT NULL
                CONSTRAINT PK_DistinteBaseRevisioni PRIMARY KEY,
            IdDistintaBase INT NOT NULL,
            NumeroRevisione INT NOT NULL,
            Stato NVARCHAR(20) NOT NULL,
            Note NVARCHAR(500) NULL,
            DataPubblicazione DATETIME2(0) NULL,
            DataCreazione DATETIME2(0) NOT NULL,
            DataModifica DATETIME2(0) NULL,
            UtenteCreazione NVARCHAR(256) NOT NULL,
            UtenteModifica NVARCHAR(256) NULL,
            VersioneRiga ROWVERSION NOT NULL,
            CONSTRAINT FK_DistinteBaseRevisioni_DistinteBase
                FOREIGN KEY (IdDistintaBase) REFERENCES dbo.DistinteBase(IdDistintaBase),
            CONSTRAINT UQ_DistinteBaseRevisioni_Numero
                UNIQUE (IdDistintaBase, NumeroRevisione),
            CONSTRAINT CK_DistinteBaseRevisioni_Numero
                CHECK (NumeroRevisione > 0),
            CONSTRAINT CK_DistinteBaseRevisioni_Stato
                CHECK (Stato IN (N'Bozza', N'Pubblicata', N'Superata'))
        );
    END;

    IF OBJECT_ID(N'dbo.DistinteBaseRevisioniStatiAudit', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.DistinteBaseRevisioniStatiAudit
        (
            IdAuditRevisioneDistinta BIGINT IDENTITY(1,1) NOT NULL
                CONSTRAINT PK_DistinteBaseRevisioniStatiAudit PRIMARY KEY,
            IdRevisioneDistinta INT NOT NULL,
            StatoPrecedente NVARCHAR(20) NOT NULL,
            StatoNuovo NVARCHAR(20) NOT NULL,
            Motivazione NVARCHAR(500) NOT NULL,
            Utente NVARCHAR(256) NOT NULL,
            DataModifica DATETIME2(0) NOT NULL,
            CONSTRAINT FK_DistinteBaseRevisioniStatiAudit_Revisioni
                FOREIGN KEY (IdRevisioneDistinta)
                REFERENCES dbo.DistinteBaseRevisioni(IdRevisioneDistinta)
        );
    END;

    IF NOT EXISTS
    (
        SELECT 1 FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.DistinteBaseRevisioni')
          AND name = N'UX_DistinteBaseRevisioni_Pubblicata'
    )
        CREATE UNIQUE INDEX UX_DistinteBaseRevisioni_Pubblicata
            ON dbo.DistinteBaseRevisioni(IdDistintaBase)
            WHERE Stato = N'Pubblicata';

    IF NOT EXISTS
    (
        SELECT 1 FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.DistinteBaseRevisioni')
          AND name = N'UX_DistinteBaseRevisioni_Bozza'
    )
        CREATE UNIQUE INDEX UX_DistinteBaseRevisioni_Bozza
            ON dbo.DistinteBaseRevisioni(IdDistintaBase)
            WHERE Stato = N'Bozza';

    INSERT dbo.DistinteBase
    (
        IdArticolo, DataCreazione, DataModifica,
        UtenteCreazione, UtenteModifica
    )
    SELECT nodo.IdArticolo, MIN(nodo.DataCreazione), NULL,
           N'MIGRAZIONE-TEC-016-REVISIONI', NULL
    FROM dbo.DistintaBaseNodi AS nodo
    LEFT JOIN dbo.DistinteBase AS distinta
        ON distinta.IdArticolo = nodo.IdArticolo
    WHERE distinta.IdDistintaBase IS NULL
    GROUP BY nodo.IdArticolo;

    INSERT dbo.DistinteBaseRevisioni
    (
        IdDistintaBase, NumeroRevisione, Stato, Note,
        DataPubblicazione, DataCreazione, DataModifica,
        UtenteCreazione, UtenteModifica
    )
    SELECT distinta.IdDistintaBase, 1, N'Pubblicata',
           N'Revisione iniziale migrata dalla distinta esistente.',
           SYSDATETIME(), distinta.DataCreazione, NULL,
           N'MIGRAZIONE-TEC-016-REVISIONI', NULL
    FROM dbo.DistinteBase AS distinta
    WHERE EXISTS
    (
        SELECT 1 FROM dbo.DistintaBaseNodi AS nodo
        WHERE nodo.IdArticolo = distinta.IdArticolo
    )
      AND NOT EXISTS
    (
        SELECT 1 FROM dbo.DistinteBaseRevisioni AS revisione
        WHERE revisione.IdDistintaBase = distinta.IdDistintaBase
    );

    IF COL_LENGTH(N'dbo.DistintaBaseNodi', N'IdRevisioneDistinta') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.DistintaBaseNodi ADD IdRevisioneDistinta INT NULL;';

    EXEC sys.sp_executesql N'
        UPDATE nodo
        SET IdRevisioneDistinta = revisione.IdRevisioneDistinta
        FROM dbo.DistintaBaseNodi AS nodo
        INNER JOIN dbo.DistinteBase AS distinta
            ON distinta.IdArticolo = nodo.IdArticolo
        INNER JOIN dbo.DistinteBaseRevisioni AS revisione
            ON revisione.IdDistintaBase = distinta.IdDistintaBase
           AND revisione.NumeroRevisione = 1
        WHERE nodo.IdRevisioneDistinta IS NULL;';

    /*
        Anche questo blocco deve essere dinamico: SQL Server compila il batch
        esterno prima che l'ALTER TABLE alla riga precedente abbia creato la
        colonna IdRevisioneDistinta.
    */
    EXEC sys.sp_executesql N'
        IF EXISTS
        (
            SELECT 1 FROM dbo.DistintaBaseNodi
            WHERE IdRevisioneDistinta IS NULL
        )
            THROW 53694, ''TEC-016-REVISIONI: migrazione dei nodi non completata.'', 1;

        IF EXISTS
        (
            SELECT 1
            FROM dbo.DistintaBaseNodi AS figlio
            INNER JOIN dbo.DistintaBaseNodi AS padre
                ON padre.IdNodoDistinta = figlio.IdNodoPadre
            WHERE figlio.IdRevisioneDistinta <> padre.IdRevisioneDistinta
        )
            THROW 53695, ''TEC-016-REVISIONI: rilevata una relazione padre-figlio fra revisioni differenti.'', 1;

        ALTER TABLE dbo.DistintaBaseNodi
            ALTER COLUMN IdRevisioneDistinta INT NOT NULL;

        IF NOT EXISTS
        (
            SELECT 1 FROM sys.foreign_keys
            WHERE parent_object_id = OBJECT_ID(N''dbo.DistintaBaseNodi'')
              AND name = N''FK_DistintaBaseNodi_Revisioni''
        )
            ALTER TABLE dbo.DistintaBaseNodi WITH CHECK
                ADD CONSTRAINT FK_DistintaBaseNodi_Revisioni
                FOREIGN KEY (IdRevisioneDistinta)
                REFERENCES dbo.DistinteBaseRevisioni(IdRevisioneDistinta);

        IF NOT EXISTS
        (
            SELECT 1 FROM sys.indexes
            WHERE object_id = OBJECT_ID(N''dbo.DistintaBaseNodi'')
              AND name = N''UX_DistintaBaseNodi_IdNodoRevisione''
        )
            CREATE UNIQUE INDEX UX_DistintaBaseNodi_IdNodoRevisione
                ON dbo.DistintaBaseNodi(IdNodoDistinta, IdRevisioneDistinta);

        IF NOT EXISTS
        (
            SELECT 1 FROM sys.foreign_keys
            WHERE parent_object_id = OBJECT_ID(N''dbo.DistintaBaseNodi'')
              AND name = N''FK_DistintaBaseNodi_PadreRevisione''
        )
            ALTER TABLE dbo.DistintaBaseNodi WITH CHECK
                ADD CONSTRAINT FK_DistintaBaseNodi_PadreRevisione
                FOREIGN KEY (IdNodoPadre, IdRevisioneDistinta)
                REFERENCES dbo.DistintaBaseNodi(IdNodoDistinta, IdRevisioneDistinta);

        IF EXISTS
        (
            SELECT 1 FROM sys.indexes
            WHERE object_id = OBJECT_ID(N''dbo.DistintaBaseNodi'')
              AND name = N''UX_DistintaBaseNodi_RadiceAttiva''
        )
            DROP INDEX UX_DistintaBaseNodi_RadiceAttiva
                ON dbo.DistintaBaseNodi;

        CREATE UNIQUE INDEX UX_DistintaBaseNodi_RadiceAttiva
            ON dbo.DistintaBaseNodi(IdRevisioneDistinta)
            WHERE IdNodoPadre IS NULL AND Attivo = 1;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Articoli
        @Ricerca NVARCHAR(200) = NULL
    AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @Filtro NVARCHAR(200) = NULLIF(LTRIM(RTRIM(@Ricerca)), N'''');
        SELECT articolo.IdArticolo, articolo.CodiceArticolo,
               articolo.Descrizione, articolo.Versione, articolo.Attivo,
               COALESCE(CONVERT(INT, nodi.NumeroNodiAttivi), 0) AS NumeroNodiAttivi,
               COALESCE(CONVERT(INT, nodi.NumeroNodiTotali), 0) AS NumeroNodiTotali,
               COALESCE(revisioni.NumeroRevisioni, 0) AS NumeroRevisioni,
               pubblicata.IdRevisioneDistinta AS IdRevisionePubblicata,
               pubblicata.NumeroRevisione AS NumeroRevisionePubblicata,
               bozza.IdRevisioneDistinta AS IdRevisioneBozza,
               bozza.NumeroRevisione AS NumeroRevisioneBozza
        FROM dbo.Articoli AS articolo
        LEFT JOIN dbo.DistinteBase AS distinta
            ON distinta.IdArticolo = articolo.IdArticolo
        OUTER APPLY
        (
            SELECT COUNT(*) AS NumeroRevisioni
            FROM dbo.DistinteBaseRevisioni AS r
            WHERE r.IdDistintaBase = distinta.IdDistintaBase
        ) AS revisioni
        OUTER APPLY
        (
            SELECT TOP (1) r.IdRevisioneDistinta, r.NumeroRevisione
            FROM dbo.DistinteBaseRevisioni AS r
            WHERE r.IdDistintaBase = distinta.IdDistintaBase
              AND r.Stato = N''Pubblicata''
        ) AS pubblicata
        OUTER APPLY
        (
            SELECT TOP (1) r.IdRevisioneDistinta, r.NumeroRevisione
            FROM dbo.DistinteBaseRevisioni AS r
            WHERE r.IdDistintaBase = distinta.IdDistintaBase
              AND r.Stato = N''Bozza''
        ) AS bozza
        OUTER APPLY
        (
            SELECT SUM(CASE WHEN n.Attivo = 1 THEN 1 ELSE 0 END) AS NumeroNodiAttivi,
                   COUNT(*) AS NumeroNodiTotali
            FROM dbo.DistintaBaseNodi AS n
            WHERE n.IdRevisioneDistinta = COALESCE(bozza.IdRevisioneDistinta, pubblicata.IdRevisioneDistinta)
        ) AS nodi
        WHERE @Filtro IS NULL
           OR articolo.CodiceArticolo LIKE N''%'' + @Filtro + N''%''
           OR articolo.Descrizione LIKE N''%'' + @Filtro + N''%''
        ORDER BY articolo.CodiceArticolo;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Lavorazioni_Elenco
        @IdNodoDistinta INT
    AS
    BEGIN
        SET NOCOUNT ON;
        SELECT distinta.IdDistintaLavorazione, distinta.IdNodoDistinta,
               nodo.IdArticolo, distinta.IdLavorazione,
               lavorazione.CodiceLavorazione,
               lavorazione.Descrizione AS DescrizioneLavorazione,
               distinta.Sequenza, distinta.TempoSetupMin,
               distinta.TempoPezzoMin, distinta.CostoOrario,
               distinta.CostoFisso, distinta.IdModelloCiclo,
               distinta.Note, distinta.DataCreazione, distinta.DataModifica,
               distinta.UtenteCreazione, distinta.UtenteModifica,
               distinta.VersioneRiga
        FROM dbo.DistintaLavorazioni AS distinta
        INNER JOIN dbo.DistintaBaseNodi AS nodo
            ON nodo.IdNodoDistinta = distinta.IdNodoDistinta
        INNER JOIN dbo.Lavorazioni AS lavorazione
            ON lavorazione.IdLavorazione = distinta.IdLavorazione
        WHERE distinta.IdNodoDistinta = @IdNodoDistinta
        ORDER BY distinta.Sequenza, distinta.IdDistintaLavorazione;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Lavorazioni_Dettaglio
        @IdDistintaLavorazione INT
    AS
    BEGIN
        SET NOCOUNT ON;
        SELECT distinta.IdDistintaLavorazione, distinta.IdNodoDistinta,
               nodo.IdArticolo, distinta.IdLavorazione,
               lavorazione.CodiceLavorazione,
               lavorazione.Descrizione AS DescrizioneLavorazione,
               distinta.Sequenza, distinta.TempoSetupMin,
               distinta.TempoPezzoMin, distinta.CostoOrario,
               distinta.CostoFisso, distinta.IdModelloCiclo,
               distinta.Note, distinta.DataCreazione, distinta.DataModifica,
               distinta.UtenteCreazione, distinta.UtenteModifica,
               distinta.VersioneRiga
        FROM dbo.DistintaLavorazioni AS distinta
        INNER JOIN dbo.DistintaBaseNodi AS nodo
            ON nodo.IdNodoDistinta = distinta.IdNodoDistinta
        INNER JOIN dbo.Lavorazioni AS lavorazione
            ON lavorazione.IdLavorazione = distinta.IdLavorazione
        WHERE distinta.IdDistintaLavorazione = @IdDistintaLavorazione;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Lavorazioni_Crea
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
              AND nodo.Attivo = 1 AND revisione.Stato = N''Bozza''
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

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Lavorazioni_Aggiorna
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
              AND revisione.Stato = N''Bozza''
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

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Lavorazioni_Elimina
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
              AND revisione.Stato = N''Bozza''
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

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.sp_EsplodiDistintaSuRigaPreventivo
        @IdRigaPreventivo INT,
        @SovrascriviSnapshot BIT = 1
    AS
    BEGIN
        SET NOCOUNT ON;
        THROW 53620, ''Procedura storica non compatibile con le revisioni. Usare il nuovo flusso applicativo TEC-016.'', 1;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.sp_RigeneraDistintaRigaPreventivo
        @IdRigaPreventivo INT
    AS
    BEGIN
        SET NOCOUNT ON;
        THROW 53620, ''Procedura storica non compatibile con le revisioni. Usare il nuovo flusso applicativo TEC-016.'', 1;
    END;';
    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Nodi_Aggiorna
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
              AND Stato = N''Bozza''
        )
            THROW 53606, ''La revisione non e una bozza modificabile.'', 1;
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

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Nodi_ImpostaStato
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
            WHERE IdRevisioneDistinta = @IdRevisioneDistinta AND Stato = N''Bozza''
        )
            THROW 53606, ''La revisione non e una bozza modificabile.'', 1;
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

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Nodi_Elimina
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
            WHERE IdRevisioneDistinta = @IdRevisioneDistinta AND Stato = N''Bozza''
        )
            THROW 53606, ''La revisione non e una bozza modificabile.'', 1;
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

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Materiali_Elenco
        @IdNodoDistinta INT
    AS
    BEGIN
        SET NOCOUNT ON;
        SELECT distinta.IdDistintaMateriale, distinta.IdNodoDistinta,
               nodo.IdArticolo, distinta.IdMateriale,
               materiale.CodiceMateriale,
               materiale.Descrizione AS DescrizioneMateriale,
               unita.CodiceUM, distinta.Quantita, distinta.CoeffScartoPerc,
               distinta.CostoUnitario, distinta.Note, distinta.DataCreazione,
               distinta.DataModifica, distinta.UtenteCreazione,
               distinta.UtenteModifica, distinta.VersioneRiga
        FROM dbo.DistintaMateriali AS distinta
        INNER JOIN dbo.DistintaBaseNodi AS nodo
            ON nodo.IdNodoDistinta = distinta.IdNodoDistinta
        INNER JOIN dbo.Materiali AS materiale
            ON materiale.IdMateriale = distinta.IdMateriale
        INNER JOIN dbo.UnitaMisura AS unita ON unita.IdUM = materiale.IdUM
        WHERE distinta.IdNodoDistinta = @IdNodoDistinta
        ORDER BY materiale.CodiceMateriale;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Materiali_Dettaglio
        @IdDistintaMateriale INT
    AS
    BEGIN
        SET NOCOUNT ON;
        SELECT distinta.IdDistintaMateriale, distinta.IdNodoDistinta,
               nodo.IdArticolo, distinta.IdMateriale,
               materiale.CodiceMateriale,
               materiale.Descrizione AS DescrizioneMateriale,
               unita.CodiceUM, distinta.Quantita, distinta.CoeffScartoPerc,
               distinta.CostoUnitario, distinta.Note, distinta.DataCreazione,
               distinta.DataModifica, distinta.UtenteCreazione,
               distinta.UtenteModifica, distinta.VersioneRiga
        FROM dbo.DistintaMateriali AS distinta
        INNER JOIN dbo.DistintaBaseNodi AS nodo
            ON nodo.IdNodoDistinta = distinta.IdNodoDistinta
        INNER JOIN dbo.Materiali AS materiale
            ON materiale.IdMateriale = distinta.IdMateriale
        INNER JOIN dbo.UnitaMisura AS unita ON unita.IdUM = materiale.IdUM
        WHERE distinta.IdDistintaMateriale = @IdDistintaMateriale;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Materiali_Crea
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
              AND nodo.Attivo = 1 AND revisione.Stato = N''Bozza''
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

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Materiali_Aggiorna
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
              AND revisione.Stato = N''Bozza''
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

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Materiali_Elimina
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
              AND revisione.Stato = N''Bozza''
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

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Revisioni_Elenco
        @IdArticolo INT
    AS
    BEGIN
        SET NOCOUNT ON;
        SELECT revisione.IdRevisioneDistinta, revisione.IdDistintaBase,
               distinta.IdArticolo, articolo.CodiceArticolo,
               articolo.Descrizione AS DescrizioneArticolo,
               revisione.NumeroRevisione, revisione.Stato, revisione.Note,
               revisione.DataPubblicazione, COUNT(nodo.IdNodoDistinta) AS NumeroNodi
        FROM dbo.DistinteBaseRevisioni AS revisione
        INNER JOIN dbo.DistinteBase AS distinta
            ON distinta.IdDistintaBase = revisione.IdDistintaBase
        INNER JOIN dbo.Articoli AS articolo
            ON articolo.IdArticolo = distinta.IdArticolo
        LEFT JOIN dbo.DistintaBaseNodi AS nodo
            ON nodo.IdRevisioneDistinta = revisione.IdRevisioneDistinta
        WHERE distinta.IdArticolo = @IdArticolo
        GROUP BY revisione.IdRevisioneDistinta, revisione.IdDistintaBase,
                 distinta.IdArticolo, articolo.CodiceArticolo, articolo.Descrizione,
                 revisione.NumeroRevisione, revisione.Stato, revisione.Note,
                 revisione.DataPubblicazione
        ORDER BY revisione.NumeroRevisione DESC;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Revisioni_Dettaglio
        @IdRevisioneDistinta INT
    AS
    BEGIN
        SET NOCOUNT ON;
        SELECT revisione.IdRevisioneDistinta, revisione.IdDistintaBase,
               distinta.IdArticolo, articolo.CodiceArticolo,
               articolo.Descrizione AS DescrizioneArticolo,
               revisione.NumeroRevisione, revisione.Stato, revisione.Note,
               revisione.DataPubblicazione, COUNT(nodo.IdNodoDistinta) AS NumeroNodi,
               revisione.DataCreazione, revisione.DataModifica,
               revisione.UtenteCreazione, revisione.UtenteModifica,
               revisione.VersioneRiga
        FROM dbo.DistinteBaseRevisioni AS revisione
        INNER JOIN dbo.DistinteBase AS distinta
            ON distinta.IdDistintaBase = revisione.IdDistintaBase
        INNER JOIN dbo.Articoli AS articolo
            ON articolo.IdArticolo = distinta.IdArticolo
        LEFT JOIN dbo.DistintaBaseNodi AS nodo
            ON nodo.IdRevisioneDistinta = revisione.IdRevisioneDistinta
        WHERE revisione.IdRevisioneDistinta = @IdRevisioneDistinta
        GROUP BY revisione.IdRevisioneDistinta, revisione.IdDistintaBase,
                 distinta.IdArticolo, articolo.CodiceArticolo, articolo.Descrizione,
                 revisione.NumeroRevisione, revisione.Stato, revisione.Note,
                 revisione.DataPubblicazione, revisione.DataCreazione,
                 revisione.DataModifica, revisione.UtenteCreazione,
                 revisione.UtenteModifica, revisione.VersioneRiga;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Revisioni_CreaBozza
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
            WHERE IdDistintaBase = @IdDistintaBase AND Stato = N''Bozza''
        )
            THROW 53603, ''Esiste gia una revisione in bozza.'', 1;
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
            @IdDistintaBase, @NumeroRevisione, N''Bozza'', @Note,
            NULL, SYSDATETIME(), NULL, @Utente, NULL
        );
        DECLARE @IdRevisioneDistinta INT = CONVERT(INT, SCOPE_IDENTITY());
        COMMIT TRANSACTION;
        SELECT @IdRevisioneDistinta;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Revisioni_Pubblica
        @IdRevisioneDistinta INT, @Motivazione NVARCHAR(500),
        @Utente NVARCHAR(256), @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON; SET XACT_ABORT ON;
        SET @Motivazione = NULLIF(LTRIM(RTRIM(@Motivazione)), N'''');
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
        IF @Motivazione IS NULL OR @Utente IS NULL
            THROW 53604, ''Motivazione e utente sono obbligatori.'', 1;
        BEGIN TRANSACTION;
        DECLARE @IdDistintaBase INT, @Stato NVARCHAR(20);
        SELECT @IdDistintaBase = IdDistintaBase, @Stato = Stato
        FROM dbo.DistinteBaseRevisioni WITH (UPDLOCK, HOLDLOCK)
        WHERE IdRevisioneDistinta = @IdRevisioneDistinta;
        IF @IdDistintaBase IS NULL THROW 53605, ''Revisione non trovata.'', 1;
        IF @Stato <> N''Bozza'' THROW 53606, ''Solo una bozza puo essere pubblicata.'', 1;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.DistinteBaseRevisioni
            WHERE IdRevisioneDistinta = @IdRevisioneDistinta
              AND VersioneRiga = @VersioneRiga
        )
            THROW 53607, ''Revisione modificata da altro utente.'', 1;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.DistintaBaseNodi
            WHERE IdRevisioneDistinta = @IdRevisioneDistinta
              AND IdNodoPadre IS NULL AND Attivo = 1
        )
            THROW 53608, ''La revisione deve contenere una radice attiva.'', 1;

        INSERT dbo.DistinteBaseRevisioniStatiAudit
        (
            IdRevisioneDistinta, StatoPrecedente, StatoNuovo,
            Motivazione, Utente, DataModifica
        )
        SELECT IdRevisioneDistinta, Stato, N''Superata'',
               @Motivazione, @Utente, SYSDATETIME()
        FROM dbo.DistinteBaseRevisioni
        WHERE IdDistintaBase = @IdDistintaBase AND Stato = N''Pubblicata'';

        UPDATE dbo.DistinteBaseRevisioni
        SET Stato = N''Superata'', DataModifica = SYSDATETIME(),
            UtenteModifica = @Utente
        WHERE IdDistintaBase = @IdDistintaBase AND Stato = N''Pubblicata'';

        INSERT dbo.DistinteBaseRevisioniStatiAudit
        (
            IdRevisioneDistinta, StatoPrecedente, StatoNuovo,
            Motivazione, Utente, DataModifica
        )
        VALUES
        (
            @IdRevisioneDistinta, N''Bozza'', N''Pubblicata'',
            @Motivazione, @Utente, SYSDATETIME()
        );

        UPDATE dbo.DistinteBaseRevisioni
        SET Stato = N''Pubblicata'', DataPubblicazione = SYSDATETIME(),
            DataModifica = SYSDATETIME(), UtenteModifica = @Utente
        WHERE IdRevisioneDistinta = @IdRevisioneDistinta
          AND VersioneRiga = @VersioneRiga;
        IF @@ROWCOUNT = 0 THROW 53607, ''Revisione modificata da altro utente.'', 1;
        COMMIT TRANSACTION;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Revisioni_EliminaBozza
        @IdRevisioneDistinta INT
    AS
    BEGIN
        SET NOCOUNT ON; SET XACT_ABORT ON; BEGIN TRANSACTION;
        DECLARE @IdDistintaBase INT, @Stato NVARCHAR(20);
        SELECT @IdDistintaBase = IdDistintaBase, @Stato = Stato
        FROM dbo.DistinteBaseRevisioni WITH (UPDLOCK, HOLDLOCK)
        WHERE IdRevisioneDistinta = @IdRevisioneDistinta;
        IF @IdDistintaBase IS NULL THROW 53605, ''Revisione non trovata.'', 1;
        IF @Stato <> N''Bozza'' THROW 53609, ''La compensazione puo rimuovere soltanto una bozza.'', 1;
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
            THROW 53610, ''La bozza contiene ancora allegati.'', 1;
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

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Nodi_Elenco
        @IdRevisioneDistinta INT
    AS
    BEGIN
        SET NOCOUNT ON;
        ;WITH Albero AS
        (
            SELECT nodo.IdNodoDistinta, nodo.IdRevisioneDistinta,
                   nodo.IdArticolo, nodo.IdNodoPadre, nodo.IdTipoNodo,
                   nodo.CodiceNodo, nodo.DescrizioneNodo, nodo.QuantitaBase,
                   nodo.Livello, nodo.OrdineVisualizzazione, nodo.Attivo,
                   CAST(nodo.DescrizioneNodo AS NVARCHAR(MAX)) AS PercorsoCompleto,
                   CAST(RIGHT(N''000000'' + CONVERT(NVARCHAR(6), nodo.OrdineVisualizzazione), 6) AS NVARCHAR(MAX)) AS Chiave
            FROM dbo.DistintaBaseNodi AS nodo
            WHERE nodo.IdRevisioneDistinta = @IdRevisioneDistinta
              AND nodo.IdNodoPadre IS NULL
            UNION ALL
            SELECT figlio.IdNodoDistinta, figlio.IdRevisioneDistinta,
                   figlio.IdArticolo, figlio.IdNodoPadre, figlio.IdTipoNodo,
                   figlio.CodiceNodo, figlio.DescrizioneNodo, figlio.QuantitaBase,
                   figlio.Livello, figlio.OrdineVisualizzazione, figlio.Attivo,
                   CAST(padre.PercorsoCompleto + N'' > '' + figlio.DescrizioneNodo AS NVARCHAR(MAX)),
                   CAST(padre.Chiave + N''.'' + RIGHT(N''000000'' + CONVERT(NVARCHAR(6), figlio.OrdineVisualizzazione), 6) AS NVARCHAR(MAX))
            FROM dbo.DistintaBaseNodi AS figlio
            INNER JOIN Albero AS padre ON padre.IdNodoDistinta = figlio.IdNodoPadre
            WHERE figlio.IdRevisioneDistinta = @IdRevisioneDistinta
        )
        SELECT albero.IdNodoDistinta, albero.IdRevisioneDistinta,
               revisione.NumeroRevisione, revisione.Stato AS StatoRevisione,
               albero.IdArticolo, articolo.CodiceArticolo,
               articolo.Descrizione AS DescrizioneArticolo,
               albero.IdNodoPadre, albero.IdTipoNodo,
               tipo.Descrizione AS TipoNodo, albero.CodiceNodo,
               albero.DescrizioneNodo, albero.QuantitaBase, albero.Livello,
               albero.OrdineVisualizzazione, albero.Attivo,
               albero.PercorsoCompleto
        FROM Albero AS albero
        INNER JOIN dbo.DistinteBaseRevisioni AS revisione
            ON revisione.IdRevisioneDistinta = albero.IdRevisioneDistinta
        INNER JOIN dbo.Articoli AS articolo ON articolo.IdArticolo = albero.IdArticolo
        INNER JOIN dbo.TipiNodoDistinta AS tipo ON tipo.IdTipoNodo = albero.IdTipoNodo
        ORDER BY albero.Chiave
        OPTION (MAXRECURSION 32767);
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Nodi_Dettaglio
        @IdNodoDistinta INT
    AS
    BEGIN
        SET NOCOUNT ON;
        SELECT nodo.IdNodoDistinta, nodo.IdRevisioneDistinta,
               revisione.NumeroRevisione, revisione.Stato AS StatoRevisione,
               nodo.IdArticolo, articolo.CodiceArticolo,
               articolo.Descrizione AS DescrizioneArticolo,
               nodo.IdNodoPadre, nodo.IdTipoNodo, tipo.Descrizione AS TipoNodo,
               nodo.CodiceNodo, nodo.DescrizioneNodo, nodo.QuantitaBase,
               nodo.Livello, nodo.OrdineVisualizzazione, nodo.Attivo,
               albero.PercorsoCompleto, nodo.Note, nodo.DataCreazione,
               nodo.DataModifica, nodo.UtenteCreazione, nodo.UtenteModifica,
               nodo.VersioneRiga
        FROM dbo.DistintaBaseNodi AS nodo
        INNER JOIN dbo.DistinteBaseRevisioni AS revisione
            ON revisione.IdRevisioneDistinta = nodo.IdRevisioneDistinta
        INNER JOIN dbo.Articoli AS articolo ON articolo.IdArticolo = nodo.IdArticolo
        INNER JOIN dbo.TipiNodoDistinta AS tipo ON tipo.IdTipoNodo = nodo.IdTipoNodo
        LEFT JOIN dbo.vw_DistintaBaseAlbero AS albero
            ON albero.IdNodoDistinta = nodo.IdNodoDistinta
        WHERE nodo.IdNodoDistinta = @IdNodoDistinta;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Nodi_Crea
        @IdArticolo INT, @IdRevisioneDistinta INT,
        @IdNodoPadre INT = NULL, @IdTipoNodo INT,
        @CodiceNodo NVARCHAR(50) = NULL, @DescrizioneNodo NVARCHAR(200),
        @QuantitaBase DECIMAL(18,4), @OrdineVisualizzazione INT,
        @Note NVARCHAR(500) = NULL, @Utente NVARCHAR(256),
        @ConsentiTipoNodoNonAttivo BIT = 0
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
              AND revisione.Stato = N''Bozza''
        )
            THROW 53606, ''La revisione non e una bozza modificabile.'', 1;
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
        INSERT dbo.DistintaBaseNodi
        (
            IdArticolo, IdRevisioneDistinta, IdNodoPadre, IdTipoNodo,
            CodiceNodo, DescrizioneNodo, QuantitaBase, Livello,
            OrdineVisualizzazione, Attivo, Note, DataCreazione,
            DataModifica, UtenteCreazione, UtenteModifica
        )
        VALUES
        (
            @IdArticolo, @IdRevisioneDistinta, @IdNodoPadre, @IdTipoNodo,
            @CodiceNodo, @DescrizioneNodo, @QuantitaBase, @Livello,
            @OrdineVisualizzazione, 1, @Note, SYSDATETIME(),
            NULL, @Utente, NULL
        );
        DECLARE @IdNodoDistinta INT = CONVERT(INT, SCOPE_IDENTITY());
        COMMIT TRANSACTION;
        SELECT @IdNodoDistinta;
    END;';
    /* PAYLOAD TEC-016-DISTINTE-REVISIONI END */

    DECLARE @Versione INT = 2026111202;
    DECLARE @CodiceIntervento NVARCHAR(50) = N'TEC-016-DISTINTE-REVISIONI';
    DECLARE @NomeScript NVARCHAR(260) = N'TEC-016_06_Distinte_Revisioni.sql';
    -- SHA-256 del contenuto fra i marcatori PAYLOAD inclusi, normalizzato con LF.
    DECLARE @ImprontaSha256 CHAR(64) = '4DF871B042AC4198AF0E9C46B6C8E50838520CD44F710D5655749ED924E58C36';

    IF EXISTS
    (
        SELECT 1 FROM dbo.VersioniSchema
        WHERE Versione = @Versione AND CodiceIntervento = @CodiceIntervento
          AND NomeScript = @NomeScript AND ImprontaSha256 = @ImprontaSha256
    )
    BEGIN
        COMMIT TRANSACTION;
        RETURN;
    END;

    IF EXISTS
    (
        SELECT 1 FROM dbo.VersioniSchema
        WHERE Versione = @Versione OR CodiceIntervento = @CodiceIntervento
           OR NomeScript = @NomeScript
    )
        THROW 53699, 'TEC-016-REVISIONI: versione gia registrata con dati o impronta differenti.', 1;

    INSERT dbo.VersioniSchema
    (
        Versione, CodiceIntervento, NomeScript,
        Descrizione, ImprontaSha256
    )
    VALUES
    (
        @Versione, @CodiceIntervento, @NomeScript,
        N'Revisioni e duplicazione completa delle distinte base.',
        @ImprontaSha256
    );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
