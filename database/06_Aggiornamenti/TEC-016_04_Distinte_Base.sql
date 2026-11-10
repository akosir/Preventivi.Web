/*
    TEC-016 - Gestione distinte base
    Versione schema: 2026110501
    Prerequisito: versione 2026110401 (TEC-016-ARTICOLI-ALLEGATI).

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
        THROW 53490, 'TEC-016-DISTINTE: registro VersioniSchema non disponibile.', 1;

    IF NOT EXISTS
    (
        SELECT 1 FROM dbo.VersioniSchema
        WHERE Versione = 2026110401
          AND CodiceIntervento = N'TEC-016-ARTICOLI-ALLEGATI'
    )
        THROW 53491, 'TEC-016-DISTINTE: versione richiesta 2026110401 non installata.', 1;

    IF EXISTS
    (
        SELECT 1 FROM dbo.VersioniSchema
        WHERE Versione > 2026110401
          AND Versione <> 2026110501
    )
        THROW 53492, 'TEC-016-DISTINTE: il database contiene una versione successiva non riconosciuta.', 1;

    IF OBJECT_ID(N'dbo.DistintaBaseNodi', N'U') IS NULL
       OR OBJECT_ID(N'dbo.DistintaMateriali', N'U') IS NULL
       OR OBJECT_ID(N'dbo.DistintaLavorazioni', N'U') IS NULL
       OR OBJECT_ID(N'dbo.Articoli', N'U') IS NULL
       OR OBJECT_ID(N'dbo.Materiali', N'U') IS NULL
       OR OBJECT_ID(N'dbo.Lavorazioni', N'U') IS NULL
       OR OBJECT_ID(N'dbo.TipiNodoDistinta', N'U') IS NULL
       OR OBJECT_ID(N'dbo.Allegati', N'U') IS NULL
       OR OBJECT_ID(N'dbo.UnitaMisura', N'U') IS NULL
       OR OBJECT_ID(N'dbo.PreventiviRigheComponenti', N'U') IS NULL
       OR OBJECT_ID(N'dbo.PreventiviRigheMateriali', N'U') IS NULL
       OR OBJECT_ID(N'dbo.PreventiviRigheLavorazioni', N'U') IS NULL
       OR OBJECT_ID(N'dbo.OrdiniFornitoriRighe', N'U') IS NULL
       OR OBJECT_ID(N'dbo.vw_DistintaBaseAlbero', N'V') IS NULL
        THROW 53493, 'TEC-016-DISTINTE: tabelle richieste non disponibili.', 1;

    /* PAYLOAD TEC-016-DISTINTE-BASE START */
    IF EXISTS
    (
        SELECT 1
        FROM dbo.DistintaBaseNodi AS figlio
        INNER JOIN dbo.DistintaBaseNodi AS padre ON padre.IdNodoDistinta = figlio.IdNodoPadre
        WHERE padre.IdArticolo <> figlio.IdArticolo
           OR padre.IdNodoDistinta = figlio.IdNodoDistinta
    )
        THROW 53494, 'TEC-016-DISTINTE: gerarchia esistente non valida.', 1;

    IF EXISTS
    (
        SELECT IdArticolo
        FROM dbo.DistintaBaseNodi
        WHERE IdNodoPadre IS NULL AND Attivo = 1
        GROUP BY IdArticolo
        HAVING COUNT(*) > 1
    )
        THROW 53495, 'TEC-016-DISTINTE: presenti piu nodi radice attivi per articolo.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.DistintaBaseNodi AS figlio
        INNER JOIN dbo.DistintaBaseNodi AS padre ON padre.IdNodoDistinta = figlio.IdNodoPadre
        WHERE figlio.Attivo = 1 AND padre.Attivo = 0
    )
        THROW 53496, 'TEC-016-DISTINTE: presenti figli attivi sotto nodi non attivi.', 1;

    IF EXISTS
    (
        SELECT IdNodoDistinta, IdMateriale
        FROM dbo.DistintaMateriali
        GROUP BY IdNodoDistinta, IdMateriale
        HAVING COUNT(*) > 1
    )
        THROW 53497, 'TEC-016-DISTINTE: presenti materiali duplicati sullo stesso nodo.', 1;

    IF EXISTS
    (
        SELECT IdNodoDistinta, Sequenza
        FROM dbo.DistintaLavorazioni
        GROUP BY IdNodoDistinta, Sequenza
        HAVING COUNT(*) > 1
    )
        THROW 53498, 'TEC-016-DISTINTE: presenti sequenze lavorazione duplicate sullo stesso nodo.', 1;

    DECLARE @NodiRaggiunti INT;
    ;WITH Albero AS
    (
        SELECT IdNodoDistinta FROM dbo.DistintaBaseNodi WHERE IdNodoPadre IS NULL
        UNION ALL
        SELECT figlio.IdNodoDistinta
        FROM dbo.DistintaBaseNodi AS figlio
        INNER JOIN Albero AS padre ON padre.IdNodoDistinta = figlio.IdNodoPadre
    )
    SELECT @NodiRaggiunti = COUNT(*) FROM Albero OPTION (MAXRECURSION 32767);

    IF @NodiRaggiunti <> (SELECT COUNT(*) FROM dbo.DistintaBaseNodi)
        THROW 53494, 'TEC-016-DISTINTE: presenti cicli o nodi non raggiungibili da una radice.', 1;

    IF COL_LENGTH(N'dbo.DistintaBaseNodi', N'DataCreazione') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.DistintaBaseNodi ADD DataCreazione DATETIME2(0) NULL;';
    IF COL_LENGTH(N'dbo.DistintaBaseNodi', N'DataModifica') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.DistintaBaseNodi ADD DataModifica DATETIME2(0) NULL;';
    IF COL_LENGTH(N'dbo.DistintaBaseNodi', N'UtenteCreazione') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.DistintaBaseNodi ADD UtenteCreazione NVARCHAR(256) NULL;';
    IF COL_LENGTH(N'dbo.DistintaBaseNodi', N'UtenteModifica') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.DistintaBaseNodi ADD UtenteModifica NVARCHAR(256) NULL;';
    IF COL_LENGTH(N'dbo.DistintaBaseNodi', N'VersioneRiga') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.DistintaBaseNodi ADD VersioneRiga ROWVERSION NOT NULL;';

    EXEC sys.sp_executesql N'
        UPDATE dbo.DistintaBaseNodi
        SET DataCreazione = COALESCE(DataCreazione, SYSDATETIME()),
            UtenteCreazione = COALESCE(UtenteCreazione, N''MIGRAZIONE-TEC-016'');
        ALTER TABLE dbo.DistintaBaseNodi ALTER COLUMN DataCreazione DATETIME2(0) NOT NULL;
        ALTER TABLE dbo.DistintaBaseNodi ALTER COLUMN UtenteCreazione NVARCHAR(256) NOT NULL;';

    IF COL_LENGTH(N'dbo.DistintaMateriali', N'CostoUnitario') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.DistintaMateriali ADD CostoUnitario DECIMAL(18,4) NULL;';
    IF COL_LENGTH(N'dbo.DistintaMateriali', N'DataCreazione') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.DistintaMateriali ADD DataCreazione DATETIME2(0) NULL;';
    IF COL_LENGTH(N'dbo.DistintaMateriali', N'DataModifica') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.DistintaMateriali ADD DataModifica DATETIME2(0) NULL;';
    IF COL_LENGTH(N'dbo.DistintaMateriali', N'UtenteCreazione') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.DistintaMateriali ADD UtenteCreazione NVARCHAR(256) NULL;';
    IF COL_LENGTH(N'dbo.DistintaMateriali', N'UtenteModifica') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.DistintaMateriali ADD UtenteModifica NVARCHAR(256) NULL;';
    IF COL_LENGTH(N'dbo.DistintaMateriali', N'VersioneRiga') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.DistintaMateriali ADD VersioneRiga ROWVERSION NOT NULL;';

    EXEC sys.sp_executesql N'
        UPDATE distinta
        SET CostoUnitario = COALESCE(distinta.CostoUnitario, materiale.CostoUnitario, 0),
            DataCreazione = COALESCE(distinta.DataCreazione, SYSDATETIME()),
            UtenteCreazione = COALESCE(distinta.UtenteCreazione, N''MIGRAZIONE-TEC-016'')
        FROM dbo.DistintaMateriali AS distinta
        LEFT JOIN dbo.Materiali AS materiale ON materiale.IdMateriale = distinta.IdMateriale;
        ALTER TABLE dbo.DistintaMateriali ALTER COLUMN CostoUnitario DECIMAL(18,4) NOT NULL;
        ALTER TABLE dbo.DistintaMateriali ALTER COLUMN DataCreazione DATETIME2(0) NOT NULL;
        ALTER TABLE dbo.DistintaMateriali ALTER COLUMN UtenteCreazione NVARCHAR(256) NOT NULL;';

    IF COL_LENGTH(N'dbo.DistintaLavorazioni', N'DataCreazione') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.DistintaLavorazioni ADD DataCreazione DATETIME2(0) NULL;';
    IF COL_LENGTH(N'dbo.DistintaLavorazioni', N'DataModifica') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.DistintaLavorazioni ADD DataModifica DATETIME2(0) NULL;';
    IF COL_LENGTH(N'dbo.DistintaLavorazioni', N'UtenteCreazione') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.DistintaLavorazioni ADD UtenteCreazione NVARCHAR(256) NULL;';
    IF COL_LENGTH(N'dbo.DistintaLavorazioni', N'UtenteModifica') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.DistintaLavorazioni ADD UtenteModifica NVARCHAR(256) NULL;';
    IF COL_LENGTH(N'dbo.DistintaLavorazioni', N'VersioneRiga') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.DistintaLavorazioni ADD VersioneRiga ROWVERSION NOT NULL;';

    EXEC sys.sp_executesql N'
        UPDATE dbo.DistintaLavorazioni
        SET DataCreazione = COALESCE(DataCreazione, SYSDATETIME()),
            UtenteCreazione = COALESCE(UtenteCreazione, N''MIGRAZIONE-TEC-016'');
        ALTER TABLE dbo.DistintaLavorazioni ALTER COLUMN DataCreazione DATETIME2(0) NOT NULL;
        ALTER TABLE dbo.DistintaLavorazioni ALTER COLUMN UtenteCreazione NVARCHAR(256) NOT NULL;';

    ;WITH Livelli AS
    (
        SELECT IdNodoDistinta, 0 AS LivelloCalcolato
        FROM dbo.DistintaBaseNodi WHERE IdNodoPadre IS NULL
        UNION ALL
        SELECT figlio.IdNodoDistinta, padre.LivelloCalcolato + 1
        FROM dbo.DistintaBaseNodi AS figlio
        INNER JOIN Livelli AS padre ON padre.IdNodoDistinta = figlio.IdNodoPadre
    )
    UPDATE nodo SET Livello = livelli.LivelloCalcolato
    FROM dbo.DistintaBaseNodi AS nodo
    INNER JOIN Livelli AS livelli ON livelli.IdNodoDistinta = nodo.IdNodoDistinta
    OPTION (MAXRECURSION 32767);

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.DistintaBaseNodi') AND name = N'UX_DistintaBaseNodi_RadiceAttiva')
        EXEC sys.sp_executesql N'CREATE UNIQUE INDEX UX_DistintaBaseNodi_RadiceAttiva ON dbo.DistintaBaseNodi(IdArticolo) WHERE IdNodoPadre IS NULL AND Attivo = 1;';
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.DistintaMateriali') AND name = N'UX_DistintaMateriali_NodoMateriale')
        EXEC sys.sp_executesql N'CREATE UNIQUE INDEX UX_DistintaMateriali_NodoMateriale ON dbo.DistintaMateriali(IdNodoDistinta, IdMateriale);';
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.DistintaLavorazioni') AND name = N'UX_DistintaLavorazioni_NodoSequenza')
        EXEC sys.sp_executesql N'CREATE UNIQUE INDEX UX_DistintaLavorazioni_NodoSequenza ON dbo.DistintaLavorazioni(IdNodoDistinta, Sequenza);';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Articoli
        @Ricerca NVARCHAR(200) = NULL
    AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @Filtro NVARCHAR(200) = NULLIF(LTRIM(RTRIM(@Ricerca)), N'''');
        SELECT articolo.IdArticolo, articolo.CodiceArticolo, articolo.Descrizione,
               articolo.Versione, articolo.Attivo,
               SUM(CASE WHEN nodo.Attivo = 1 THEN 1 ELSE 0 END) AS NumeroNodiAttivi,
               COUNT(nodo.IdNodoDistinta) AS NumeroNodiTotali
        FROM dbo.Articoli AS articolo
        LEFT JOIN dbo.DistintaBaseNodi AS nodo ON nodo.IdArticolo = articolo.IdArticolo
        WHERE @Filtro IS NULL OR articolo.CodiceArticolo LIKE N''%'' + @Filtro + N''%'' OR articolo.Descrizione LIKE N''%'' + @Filtro + N''%''
        GROUP BY articolo.IdArticolo, articolo.CodiceArticolo, articolo.Descrizione, articolo.Versione, articolo.Attivo
        ORDER BY articolo.CodiceArticolo;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_TipiNodo_Lookup
        @IdCorrente INT = NULL
    AS
    BEGIN
        SET NOCOUNT ON;
        SELECT IdTipoNodo, Descrizione, Attivo
        FROM dbo.TipiNodoDistinta
        WHERE Attivo = 1 OR IdTipoNodo = @IdCorrente
        ORDER BY Descrizione;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Nodi_Elenco
        @IdArticolo INT
    AS
    BEGIN
        SET NOCOUNT ON;
        WITH Albero AS
        (
            SELECT nodo.IdNodoDistinta, nodo.IdArticolo, nodo.IdNodoPadre, nodo.IdTipoNodo,
                   nodo.CodiceNodo, nodo.DescrizioneNodo, nodo.QuantitaBase, nodo.Livello,
                   nodo.OrdineVisualizzazione, nodo.Attivo,
                   CAST(nodo.DescrizioneNodo AS NVARCHAR(MAX)) AS PercorsoCompleto,
                   CAST(RIGHT(N''000000'' + CONVERT(NVARCHAR(6), nodo.OrdineVisualizzazione), 6) AS NVARCHAR(MAX)) AS Chiave
            FROM dbo.DistintaBaseNodi AS nodo
            WHERE nodo.IdArticolo = @IdArticolo AND nodo.IdNodoPadre IS NULL
            UNION ALL
            SELECT figlio.IdNodoDistinta, figlio.IdArticolo, figlio.IdNodoPadre, figlio.IdTipoNodo,
                   figlio.CodiceNodo, figlio.DescrizioneNodo, figlio.QuantitaBase, figlio.Livello,
                   figlio.OrdineVisualizzazione, figlio.Attivo,
                   CAST(padre.PercorsoCompleto + N'' > '' + figlio.DescrizioneNodo AS NVARCHAR(MAX)),
                   CAST(padre.Chiave + N''.'' + RIGHT(N''000000'' + CONVERT(NVARCHAR(6), figlio.OrdineVisualizzazione), 6) AS NVARCHAR(MAX))
            FROM dbo.DistintaBaseNodi AS figlio
            INNER JOIN Albero AS padre ON padre.IdNodoDistinta = figlio.IdNodoPadre
            WHERE figlio.IdArticolo = @IdArticolo
        )
        SELECT albero.IdNodoDistinta, albero.IdArticolo, articolo.CodiceArticolo,
               articolo.Descrizione AS DescrizioneArticolo, albero.IdNodoPadre,
               albero.IdTipoNodo, tipo.Descrizione AS TipoNodo, albero.CodiceNodo,
               albero.DescrizioneNodo, albero.QuantitaBase, albero.Livello,
               albero.OrdineVisualizzazione, albero.Attivo, albero.PercorsoCompleto
        FROM Albero AS albero
        INNER JOIN dbo.Articoli AS articolo ON articolo.IdArticolo = albero.IdArticolo
        INNER JOIN dbo.TipiNodoDistinta AS tipo ON tipo.IdTipoNodo = albero.IdTipoNodo
        ORDER BY albero.Chiave, albero.IdNodoDistinta
        OPTION (MAXRECURSION 32767);
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Nodi_Dettaglio
        @IdNodoDistinta INT
    AS
    BEGIN
        SET NOCOUNT ON;
        SELECT nodo.IdNodoDistinta, nodo.IdArticolo, articolo.CodiceArticolo,
               articolo.Descrizione AS DescrizioneArticolo, nodo.IdNodoPadre,
               nodo.IdTipoNodo, tipo.Descrizione AS TipoNodo, nodo.CodiceNodo,
               nodo.DescrizioneNodo, nodo.QuantitaBase, nodo.Livello,
               nodo.OrdineVisualizzazione, nodo.Attivo,
               COALESCE(albero.PercorsoCompleto, nodo.DescrizioneNodo) AS PercorsoCompleto,
               nodo.Note, nodo.DataCreazione, nodo.DataModifica,
               nodo.UtenteCreazione, nodo.UtenteModifica, nodo.VersioneRiga
        FROM dbo.DistintaBaseNodi AS nodo
        INNER JOIN dbo.Articoli AS articolo ON articolo.IdArticolo = nodo.IdArticolo
        INNER JOIN dbo.TipiNodoDistinta AS tipo ON tipo.IdTipoNodo = nodo.IdTipoNodo
        LEFT JOIN dbo.vw_DistintaBaseAlbero AS albero ON albero.IdNodoDistinta = nodo.IdNodoDistinta
        WHERE nodo.IdNodoDistinta = @IdNodoDistinta;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Nodi_Crea
        @IdArticolo INT, @IdNodoPadre INT = NULL, @IdTipoNodo INT,
        @CodiceNodo NVARCHAR(50) = NULL, @DescrizioneNodo NVARCHAR(200),
        @QuantitaBase DECIMAL(18,4), @OrdineVisualizzazione INT,
        @Note NVARCHAR(500) = NULL, @Utente NVARCHAR(256)
    AS
    BEGIN
        SET NOCOUNT ON; SET XACT_ABORT ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
        SET @CodiceNodo = NULLIF(LTRIM(RTRIM(@CodiceNodo)), N'''');
        SET @DescrizioneNodo = NULLIF(LTRIM(RTRIM(@DescrizioneNodo)), N'''');
        SET @Note = NULLIF(LTRIM(RTRIM(@Note)), N'''');
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
        IF @DescrizioneNodo IS NULL OR @Utente IS NULL OR @QuantitaBase <= 0 OR @OrdineVisualizzazione < 0 THROW 53401, ''Dati nodo non validi.'', 1;
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.Articoli WITH (UPDLOCK, HOLDLOCK) WHERE IdArticolo = @IdArticolo AND Attivo = 1) THROW 53402, ''Articolo non valido o non attivo.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.TipiNodoDistinta WITH (UPDLOCK, HOLDLOCK) WHERE IdTipoNodo = @IdTipoNodo AND Attivo = 1) THROW 53403, ''Tipo nodo non valido o non attivo.'', 1;
        DECLARE @Livello INT = 0;
        IF @IdNodoPadre IS NULL
        BEGIN
            IF EXISTS (SELECT 1 FROM dbo.DistintaBaseNodi WITH (UPDLOCK, HOLDLOCK) WHERE IdArticolo = @IdArticolo AND IdNodoPadre IS NULL AND Attivo = 1) THROW 53406, ''Radice attiva gia presente.'', 1;
        END
        ELSE
        BEGIN
            SELECT @Livello = Livello + 1 FROM dbo.DistintaBaseNodi WITH (UPDLOCK, HOLDLOCK) WHERE IdNodoDistinta = @IdNodoPadre AND IdArticolo = @IdArticolo AND Attivo = 1;
            IF @Livello = 0 THROW 53404, ''Nodo padre non valido.'', 1;
        END;
        INSERT INTO dbo.DistintaBaseNodi (IdArticolo, IdNodoPadre, IdTipoNodo, CodiceNodo, DescrizioneNodo, QuantitaBase, Livello, OrdineVisualizzazione, Attivo, Note, DataCreazione, DataModifica, UtenteCreazione, UtenteModifica)
        VALUES (@IdArticolo, @IdNodoPadre, @IdTipoNodo, @CodiceNodo, @DescrizioneNodo, @QuantitaBase, @Livello, @OrdineVisualizzazione, 1, @Note, SYSDATETIME(), NULL, @Utente, NULL);
        DECLARE @IdNodoDistinta INT = CONVERT(INT, SCOPE_IDENTITY());
        COMMIT TRANSACTION; SELECT @IdNodoDistinta;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Nodi_Aggiorna
        @IdNodoDistinta INT, @IdArticolo INT, @IdNodoPadre INT = NULL,
        @IdTipoNodo INT, @CodiceNodo NVARCHAR(50) = NULL,
        @DescrizioneNodo NVARCHAR(200), @QuantitaBase DECIMAL(18,4),
        @OrdineVisualizzazione INT, @Note NVARCHAR(500) = NULL,
        @Utente NVARCHAR(256), @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON; SET XACT_ABORT ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
        SET @CodiceNodo = NULLIF(LTRIM(RTRIM(@CodiceNodo)), N'''');
        SET @DescrizioneNodo = NULLIF(LTRIM(RTRIM(@DescrizioneNodo)), N'''');
        SET @Note = NULLIF(LTRIM(RTRIM(@Note)), N'''');
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
        IF @DescrizioneNodo IS NULL OR @Utente IS NULL OR @QuantitaBase <= 0 OR @OrdineVisualizzazione < 0 THROW 53401, ''Dati nodo non validi.'', 1;
        BEGIN TRANSACTION;
        DECLARE @IdArticoloCorrente INT, @IdPadreCorrente INT, @IdTipoCorrente INT,
                @LivelloVecchio INT, @LivelloNuovo INT = 0, @AttivoCorrente BIT;
        SELECT @IdArticoloCorrente = IdArticolo, @IdPadreCorrente = IdNodoPadre,
               @IdTipoCorrente = IdTipoNodo, @LivelloVecchio = Livello,
               @AttivoCorrente = Attivo
        FROM dbo.DistintaBaseNodi WITH (UPDLOCK, HOLDLOCK)
        WHERE IdNodoDistinta = @IdNodoDistinta;
        IF @IdArticoloCorrente IS NULL THROW 53408, ''Nodo non trovato.'', 1;
        IF @IdArticoloCorrente <> @IdArticolo THROW 53404, ''Articolo del nodo non modificabile.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.DistintaBaseNodi WHERE IdNodoDistinta = @IdNodoDistinta AND VersioneRiga = @VersioneRiga) THROW 53407, ''Nodo modificato da altro utente.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.TipiNodoDistinta WHERE IdTipoNodo = @IdTipoNodo AND (Attivo = 1 OR IdTipoNodo = @IdTipoCorrente)) THROW 53403, ''Tipo nodo non valido.'', 1;
        IF @IdNodoPadre = @IdNodoDistinta THROW 53405, ''Ciclo non consentito.'', 1;

        IF @IdNodoPadre IS NULL
        BEGIN
            IF @AttivoCorrente = 1 AND EXISTS (SELECT 1 FROM dbo.DistintaBaseNodi WITH (UPDLOCK, HOLDLOCK) WHERE IdArticolo = @IdArticolo AND IdNodoPadre IS NULL AND Attivo = 1 AND IdNodoDistinta <> @IdNodoDistinta) THROW 53406, ''Radice attiva gia presente.'', 1;
        END
        ELSE
        BEGIN
            SELECT @LivelloNuovo = Livello + 1
            FROM dbo.DistintaBaseNodi
            WHERE IdNodoDistinta = @IdNodoPadre AND IdArticolo = @IdArticolo
              AND (Attivo = 1 OR IdNodoDistinta = @IdPadreCorrente);
            IF @LivelloNuovo = 0 THROW 53404, ''Nodo padre non valido.'', 1;
            DECLARE @Ciclo BIT = 0;
            ;WITH Discendenti AS
            (
                SELECT IdNodoDistinta FROM dbo.DistintaBaseNodi WHERE IdNodoPadre = @IdNodoDistinta
                UNION ALL
                SELECT figlio.IdNodoDistinta FROM dbo.DistintaBaseNodi AS figlio
                INNER JOIN Discendenti AS padre ON padre.IdNodoDistinta = figlio.IdNodoPadre
            )
            SELECT @Ciclo = 1 FROM Discendenti WHERE IdNodoDistinta = @IdNodoPadre OPTION (MAXRECURSION 32767);
            IF @Ciclo = 1 THROW 53405, ''Ciclo non consentito.'', 1;
        END;

        DECLARE @DifferenzaLivello INT = @LivelloNuovo - @LivelloVecchio;
        UPDATE dbo.DistintaBaseNodi
        SET IdNodoPadre = @IdNodoPadre, IdTipoNodo = @IdTipoNodo,
            CodiceNodo = @CodiceNodo, DescrizioneNodo = @DescrizioneNodo,
            QuantitaBase = @QuantitaBase, Livello = @LivelloNuovo,
            OrdineVisualizzazione = @OrdineVisualizzazione, Note = @Note,
            DataModifica = SYSDATETIME(), UtenteModifica = @Utente
        WHERE IdNodoDistinta = @IdNodoDistinta AND VersioneRiga = @VersioneRiga;
        IF @@ROWCOUNT = 0 THROW 53407, ''Nodo modificato da altro utente.'', 1;

        IF @DifferenzaLivello <> 0
        BEGIN
            ;WITH Discendenti AS
            (
                SELECT IdNodoDistinta FROM dbo.DistintaBaseNodi WHERE IdNodoPadre = @IdNodoDistinta
                UNION ALL
                SELECT figlio.IdNodoDistinta FROM dbo.DistintaBaseNodi AS figlio
                INNER JOIN Discendenti AS padre ON padre.IdNodoDistinta = figlio.IdNodoPadre
            )
            UPDATE nodo
            SET Livello = nodo.Livello + @DifferenzaLivello,
                DataModifica = SYSDATETIME(), UtenteModifica = @Utente
            FROM dbo.DistintaBaseNodi AS nodo
            INNER JOIN Discendenti AS d ON d.IdNodoDistinta = nodo.IdNodoDistinta
            OPTION (MAXRECURSION 32767);
        END;
        COMMIT TRANSACTION;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Nodi_ImpostaStato
        @IdNodoDistinta INT, @Attivo BIT, @Utente NVARCHAR(256), @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON; SET XACT_ABORT ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
        IF @Attivo IS NULL OR @Utente IS NULL THROW 53401, ''Dati stato non validi.'', 1;
        BEGIN TRANSACTION;
        DECLARE @IdArticolo INT, @IdNodoPadre INT;
        SELECT @IdArticolo = IdArticolo, @IdNodoPadre = IdNodoPadre
        FROM dbo.DistintaBaseNodi WITH (UPDLOCK, HOLDLOCK)
        WHERE IdNodoDistinta = @IdNodoDistinta;
        IF @IdArticolo IS NULL THROW 53408, ''Nodo non trovato.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.DistintaBaseNodi WHERE IdNodoDistinta = @IdNodoDistinta AND VersioneRiga = @VersioneRiga) THROW 53407, ''Nodo modificato da altro utente.'', 1;
        IF @Attivo = 0 AND EXISTS (SELECT 1 FROM dbo.DistintaBaseNodi WHERE IdNodoPadre = @IdNodoDistinta AND Attivo = 1) THROW 53409, ''Disattivare prima i nodi figli.'', 1;
        IF @Attivo = 1
        BEGIN
            IF @IdNodoPadre IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.DistintaBaseNodi WHERE IdNodoDistinta = @IdNodoPadre AND Attivo = 1) THROW 53409, ''Il nodo padre non e attivo.'', 1;
            IF @IdNodoPadre IS NULL AND EXISTS (SELECT 1 FROM dbo.DistintaBaseNodi WHERE IdArticolo = @IdArticolo AND IdNodoPadre IS NULL AND Attivo = 1 AND IdNodoDistinta <> @IdNodoDistinta) THROW 53406, ''Radice attiva gia presente.'', 1;
        END;
        UPDATE dbo.DistintaBaseNodi SET Attivo = @Attivo, DataModifica = SYSDATETIME(), UtenteModifica = @Utente
        WHERE IdNodoDistinta = @IdNodoDistinta AND VersioneRiga = @VersioneRiga;
        IF @@ROWCOUNT = 0 THROW 53407, ''Nodo modificato da altro utente.'', 1;
        COMMIT TRANSACTION;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Nodi_Elimina
        @IdNodoDistinta INT, @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON; SET XACT_ABORT ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF; BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.DistintaBaseNodi WITH (UPDLOCK, HOLDLOCK) WHERE IdNodoDistinta = @IdNodoDistinta) THROW 53408, ''Nodo non trovato.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.DistintaBaseNodi WHERE IdNodoDistinta = @IdNodoDistinta AND VersioneRiga = @VersioneRiga) THROW 53407, ''Nodo modificato da altro utente.'', 1;
        IF EXISTS (SELECT 1 FROM dbo.DistintaBaseNodi WHERE IdNodoPadre = @IdNodoDistinta)
           OR EXISTS (SELECT 1 FROM dbo.DistintaMateriali WHERE IdNodoDistinta = @IdNodoDistinta)
           OR EXISTS (SELECT 1 FROM dbo.DistintaLavorazioni WHERE IdNodoDistinta = @IdNodoDistinta)
           OR EXISTS (SELECT 1 FROM dbo.PreventiviRigheComponenti WHERE IdNodoDistinta = @IdNodoDistinta)
           OR EXISTS (SELECT 1 FROM dbo.PreventiviRigheMateriali WHERE IdNodoDistinta = @IdNodoDistinta)
           OR EXISTS (SELECT 1 FROM dbo.PreventiviRigheLavorazioni WHERE IdNodoDistinta = @IdNodoDistinta)
           OR EXISTS (SELECT 1 FROM dbo.OrdiniFornitoriRighe WHERE IdNodoDistinta = @IdNodoDistinta)
            THROW 53409, ''Nodo utilizzato o non vuoto.'', 1;
        IF EXISTS (SELECT 1 FROM dbo.Allegati WHERE Entita = N''DistintaBaseNodi'' AND IdEntita = @IdNodoDistinta) THROW 53416, ''Eliminare prima gli allegati.'', 1;
        DELETE FROM dbo.DistintaBaseNodi WHERE IdNodoDistinta = @IdNodoDistinta AND VersioneRiga = @VersioneRiga;
        COMMIT TRANSACTION;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Materiali_Lookup
        @IdCorrente INT = NULL
    AS
    BEGIN
        SET NOCOUNT ON;
        SELECT materiale.IdMateriale, materiale.CodiceMateriale, materiale.Descrizione,
               materiale.CostoUnitario, unita.CodiceUM
        FROM dbo.Materiali AS materiale
        INNER JOIN dbo.UnitaMisura AS unita ON unita.IdUM = materiale.IdUM
        WHERE materiale.Attivo = 1 OR materiale.IdMateriale = @IdCorrente
        ORDER BY materiale.CodiceMateriale;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Materiali_Elenco
        @IdNodoDistinta INT
    AS
    BEGIN
        SET NOCOUNT ON;
        SELECT distinta.IdDistintaMateriale, distinta.IdNodoDistinta, nodo.IdArticolo,
               distinta.IdMateriale, materiale.CodiceMateriale,
               materiale.Descrizione AS DescrizioneMateriale, unita.CodiceUM,
               distinta.Quantita, distinta.CoeffScartoPerc, distinta.CostoUnitario,
               distinta.Note, distinta.DataCreazione, distinta.DataModifica,
               distinta.UtenteCreazione, distinta.UtenteModifica, distinta.VersioneRiga
        FROM dbo.DistintaMateriali AS distinta
        INNER JOIN dbo.DistintaBaseNodi AS nodo ON nodo.IdNodoDistinta = distinta.IdNodoDistinta
        INNER JOIN dbo.Materiali AS materiale ON materiale.IdMateriale = distinta.IdMateriale
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
        SELECT distinta.IdDistintaMateriale, distinta.IdNodoDistinta, nodo.IdArticolo,
               distinta.IdMateriale, materiale.CodiceMateriale,
               materiale.Descrizione AS DescrizioneMateriale, unita.CodiceUM,
               distinta.Quantita, distinta.CoeffScartoPerc, distinta.CostoUnitario,
               distinta.Note, distinta.DataCreazione, distinta.DataModifica,
               distinta.UtenteCreazione, distinta.UtenteModifica, distinta.VersioneRiga
        FROM dbo.DistintaMateriali AS distinta
        INNER JOIN dbo.DistintaBaseNodi AS nodo ON nodo.IdNodoDistinta = distinta.IdNodoDistinta
        INNER JOIN dbo.Materiali AS materiale ON materiale.IdMateriale = distinta.IdMateriale
        INNER JOIN dbo.UnitaMisura AS unita ON unita.IdUM = materiale.IdUM
        WHERE distinta.IdDistintaMateriale = @IdDistintaMateriale;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Materiali_Crea
        @IdNodoDistinta INT, @IdMateriale INT, @Quantita DECIMAL(18,4),
        @CoeffScartoPerc DECIMAL(9,2), @CostoUnitario DECIMAL(18,4),
        @Note NVARCHAR(500) = NULL, @Utente NVARCHAR(256)
    AS
    BEGIN
        SET NOCOUNT ON; SET XACT_ABORT ON;
        SET @Note = NULLIF(LTRIM(RTRIM(@Note)), N''''); SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
        IF @Quantita <= 0 OR @CoeffScartoPerc < 0 OR @CostoUnitario < 0 OR @Utente IS NULL THROW 53401, ''Dati materiale non validi.'', 1;
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.DistintaBaseNodi WITH (UPDLOCK, HOLDLOCK) WHERE IdNodoDistinta = @IdNodoDistinta AND Attivo = 1) THROW 53408, ''Nodo non valido o non attivo.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.Materiali WITH (UPDLOCK, HOLDLOCK) WHERE IdMateriale = @IdMateriale AND Attivo = 1) THROW 53410, ''Materiale non valido o non attivo.'', 1;
        IF EXISTS (SELECT 1 FROM dbo.DistintaMateriali WITH (UPDLOCK, HOLDLOCK) WHERE IdNodoDistinta = @IdNodoDistinta AND IdMateriale = @IdMateriale) THROW 53411, ''Materiale gia presente.'', 1;
        INSERT INTO dbo.DistintaMateriali (IdNodoDistinta, IdMateriale, Quantita, CoeffScartoPerc, CostoUnitario, Note, DataCreazione, DataModifica, UtenteCreazione, UtenteModifica)
        VALUES (@IdNodoDistinta, @IdMateriale, @Quantita, @CoeffScartoPerc, @CostoUnitario, @Note, SYSDATETIME(), NULL, @Utente, NULL);
        DECLARE @IdDistintaMateriale INT = CONVERT(INT, SCOPE_IDENTITY()); COMMIT TRANSACTION; SELECT @IdDistintaMateriale;
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
        SET @Note = NULLIF(LTRIM(RTRIM(@Note)), N''''); SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
        IF @Quantita <= 0 OR @CoeffScartoPerc < 0 OR @CostoUnitario < 0 OR @Utente IS NULL THROW 53401, ''Dati materiale non validi.'', 1;
        BEGIN TRANSACTION;
        DECLARE @IdNodoCorrente INT, @IdMaterialeCorrente INT;
        SELECT @IdNodoCorrente = IdNodoDistinta, @IdMaterialeCorrente = IdMateriale FROM dbo.DistintaMateriali WITH (UPDLOCK, HOLDLOCK) WHERE IdDistintaMateriale = @IdDistintaMateriale;
        IF @IdNodoCorrente IS NULL THROW 53412, ''Riga materiale non trovata.'', 1;
        IF @IdNodoCorrente <> @IdNodoDistinta THROW 53408, ''Nodo della riga non modificabile.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.DistintaMateriali WHERE IdDistintaMateriale = @IdDistintaMateriale AND VersioneRiga = @VersioneRiga) THROW 53407, ''Riga modificata da altro utente.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.Materiali WHERE IdMateriale = @IdMateriale AND (Attivo = 1 OR IdMateriale = @IdMaterialeCorrente)) THROW 53410, ''Materiale non valido.'', 1;
        IF EXISTS (SELECT 1 FROM dbo.DistintaMateriali WHERE IdNodoDistinta = @IdNodoDistinta AND IdMateriale = @IdMateriale AND IdDistintaMateriale <> @IdDistintaMateriale) THROW 53411, ''Materiale gia presente.'', 1;
        UPDATE dbo.DistintaMateriali SET IdMateriale = @IdMateriale, Quantita = @Quantita,
            CoeffScartoPerc = @CoeffScartoPerc, CostoUnitario = @CostoUnitario,
            Note = @Note, DataModifica = SYSDATETIME(), UtenteModifica = @Utente
        WHERE IdDistintaMateriale = @IdDistintaMateriale AND VersioneRiga = @VersioneRiga;
        IF @@ROWCOUNT = 0 THROW 53407, ''Riga modificata da altro utente.'', 1;
        COMMIT TRANSACTION;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Materiali_Elimina
        @IdDistintaMateriale INT, @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON; SET XACT_ABORT ON; BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.DistintaMateriali WITH (UPDLOCK, HOLDLOCK) WHERE IdDistintaMateriale = @IdDistintaMateriale) THROW 53412, ''Riga materiale non trovata.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.DistintaMateriali WHERE IdDistintaMateriale = @IdDistintaMateriale AND VersioneRiga = @VersioneRiga) THROW 53407, ''Riga modificata da altro utente.'', 1;
        IF EXISTS (SELECT 1 FROM dbo.Allegati WHERE Entita = N''DistintaMateriali'' AND IdEntita = @IdDistintaMateriale) THROW 53416, ''Eliminare prima gli allegati.'', 1;
        DELETE FROM dbo.DistintaMateriali WHERE IdDistintaMateriale = @IdDistintaMateriale AND VersioneRiga = @VersioneRiga;
        COMMIT TRANSACTION;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Lavorazioni_Lookup
        @IdCorrente INT = NULL
    AS
    BEGIN
        SET NOCOUNT ON;
        SELECT IdLavorazione, CodiceLavorazione, Descrizione,
               CostoOrarioStandard, TempoSetupMinDefault, TempoPezzoMinDefault
        FROM dbo.Lavorazioni
        WHERE Attiva = 1 OR IdLavorazione = @IdCorrente
        ORDER BY CodiceLavorazione;
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
               distinta.Sequenza, distinta.TempoSetupMin, distinta.TempoPezzoMin,
               distinta.CostoOrario, distinta.CostoFisso, distinta.IdModelloCiclo,
               distinta.Note, distinta.DataCreazione, distinta.DataModifica,
               distinta.UtenteCreazione, distinta.UtenteModifica, distinta.VersioneRiga
        FROM dbo.DistintaLavorazioni AS distinta
        INNER JOIN dbo.DistintaBaseNodi AS nodo ON nodo.IdNodoDistinta = distinta.IdNodoDistinta
        INNER JOIN dbo.Lavorazioni AS lavorazione ON lavorazione.IdLavorazione = distinta.IdLavorazione
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
               distinta.Sequenza, distinta.TempoSetupMin, distinta.TempoPezzoMin,
               distinta.CostoOrario, distinta.CostoFisso, distinta.IdModelloCiclo,
               distinta.Note, distinta.DataCreazione, distinta.DataModifica,
               distinta.UtenteCreazione, distinta.UtenteModifica, distinta.VersioneRiga
        FROM dbo.DistintaLavorazioni AS distinta
        INNER JOIN dbo.DistintaBaseNodi AS nodo ON nodo.IdNodoDistinta = distinta.IdNodoDistinta
        INNER JOIN dbo.Lavorazioni AS lavorazione ON lavorazione.IdLavorazione = distinta.IdLavorazione
        WHERE distinta.IdDistintaLavorazione = @IdDistintaLavorazione;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Lavorazioni_Crea
        @IdNodoDistinta INT, @IdLavorazione INT, @Sequenza INT,
        @TempoSetupMin DECIMAL(18,2), @TempoPezzoMin DECIMAL(18,4),
        @CostoOrario DECIMAL(18,4), @CostoFisso DECIMAL(18,4),
        @Note NVARCHAR(500) = NULL, @Utente NVARCHAR(256)
    AS
    BEGIN
        SET NOCOUNT ON; SET XACT_ABORT ON;
        SET @Note = NULLIF(LTRIM(RTRIM(@Note)), N''''); SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
        IF @Sequenza <= 0 OR @TempoSetupMin < 0 OR @TempoPezzoMin < 0 OR @CostoOrario < 0 OR @CostoFisso < 0 OR @Utente IS NULL THROW 53401, ''Dati lavorazione non validi.'', 1;
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.DistintaBaseNodi WITH (UPDLOCK, HOLDLOCK) WHERE IdNodoDistinta = @IdNodoDistinta AND Attivo = 1) THROW 53408, ''Nodo non valido o non attivo.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.Lavorazioni WITH (UPDLOCK, HOLDLOCK) WHERE IdLavorazione = @IdLavorazione AND Attiva = 1) THROW 53413, ''Lavorazione non valida o non attiva.'', 1;
        IF EXISTS (SELECT 1 FROM dbo.DistintaLavorazioni WITH (UPDLOCK, HOLDLOCK) WHERE IdNodoDistinta = @IdNodoDistinta AND Sequenza = @Sequenza) THROW 53414, ''Sequenza gia utilizzata.'', 1;
        INSERT INTO dbo.DistintaLavorazioni (IdNodoDistinta, IdLavorazione, Sequenza, TempoSetupMin, TempoPezzoMin, CostoOrario, CostoFisso, IdModelloCiclo, Note, DataCreazione, DataModifica, UtenteCreazione, UtenteModifica)
        VALUES (@IdNodoDistinta, @IdLavorazione, @Sequenza, @TempoSetupMin, @TempoPezzoMin, @CostoOrario, @CostoFisso, NULL, @Note, SYSDATETIME(), NULL, @Utente, NULL);
        DECLARE @IdDistintaLavorazione INT = CONVERT(INT, SCOPE_IDENTITY()); COMMIT TRANSACTION; SELECT @IdDistintaLavorazione;
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
        SET @Note = NULLIF(LTRIM(RTRIM(@Note)), N''''); SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
        IF @Sequenza <= 0 OR @TempoSetupMin < 0 OR @TempoPezzoMin < 0 OR @CostoOrario < 0 OR @CostoFisso < 0 OR @Utente IS NULL THROW 53401, ''Dati lavorazione non validi.'', 1;
        BEGIN TRANSACTION;
        DECLARE @IdNodoCorrente INT, @IdLavorazioneCorrente INT;
        SELECT @IdNodoCorrente = IdNodoDistinta, @IdLavorazioneCorrente = IdLavorazione FROM dbo.DistintaLavorazioni WITH (UPDLOCK, HOLDLOCK) WHERE IdDistintaLavorazione = @IdDistintaLavorazione;
        IF @IdNodoCorrente IS NULL THROW 53415, ''Riga lavorazione non trovata.'', 1;
        IF @IdNodoCorrente <> @IdNodoDistinta THROW 53408, ''Nodo della riga non modificabile.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.DistintaLavorazioni WHERE IdDistintaLavorazione = @IdDistintaLavorazione AND VersioneRiga = @VersioneRiga) THROW 53407, ''Riga modificata da altro utente.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.Lavorazioni WHERE IdLavorazione = @IdLavorazione AND (Attiva = 1 OR IdLavorazione = @IdLavorazioneCorrente)) THROW 53413, ''Lavorazione non valida.'', 1;
        IF EXISTS (SELECT 1 FROM dbo.DistintaLavorazioni WHERE IdNodoDistinta = @IdNodoDistinta AND Sequenza = @Sequenza AND IdDistintaLavorazione <> @IdDistintaLavorazione) THROW 53414, ''Sequenza gia utilizzata.'', 1;
        UPDATE dbo.DistintaLavorazioni SET IdLavorazione = @IdLavorazione,
            Sequenza = @Sequenza, TempoSetupMin = @TempoSetupMin,
            TempoPezzoMin = @TempoPezzoMin, CostoOrario = @CostoOrario,
            CostoFisso = @CostoFisso, Note = @Note,
            DataModifica = SYSDATETIME(), UtenteModifica = @Utente
        WHERE IdDistintaLavorazione = @IdDistintaLavorazione AND VersioneRiga = @VersioneRiga;
        IF @@ROWCOUNT = 0 THROW 53407, ''Riga modificata da altro utente.'', 1;
        COMMIT TRANSACTION;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Lavorazioni_Elimina
        @IdDistintaLavorazione INT, @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON; SET XACT_ABORT ON; BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.DistintaLavorazioni WITH (UPDLOCK, HOLDLOCK) WHERE IdDistintaLavorazione = @IdDistintaLavorazione) THROW 53415, ''Riga lavorazione non trovata.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.DistintaLavorazioni WHERE IdDistintaLavorazione = @IdDistintaLavorazione AND VersioneRiga = @VersioneRiga) THROW 53407, ''Riga modificata da altro utente.'', 1;
        IF EXISTS (SELECT 1 FROM dbo.Allegati WHERE Entita = N''DistintaLavorazioni'' AND IdEntita = @IdDistintaLavorazione) THROW 53416, ''Eliminare prima gli allegati.'', 1;
        DELETE FROM dbo.DistintaLavorazioni WHERE IdDistintaLavorazione = @IdDistintaLavorazione AND VersioneRiga = @VersioneRiga;
        COMMIT TRANSACTION;
    END;';
    /* PAYLOAD TEC-016-DISTINTE-BASE END */

    DECLARE @Versione INT = 2026110501;
    DECLARE @CodiceIntervento NVARCHAR(50) = N'TEC-016-DISTINTE-BASE';
    DECLARE @NomeScript NVARCHAR(260) = N'TEC-016_04_Distinte_Base.sql';
    DECLARE @ImprontaSha256 CHAR(64) = '8E3861CB4DF261AA6BF0FA1D5DE1DF7B8BE71806697B249AA5B616BC07C03625';

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
        WHERE Versione = @Versione OR CodiceIntervento = @CodiceIntervento OR NomeScript = @NomeScript
    )
        THROW 53499, 'TEC-016-DISTINTE: versione gia registrata con dati o impronta differenti.', 1;

    INSERT INTO dbo.VersioniSchema (Versione, CodiceIntervento, NomeScript, Descrizione, ImprontaSha256)
    VALUES (@Versione, @CodiceIntervento, @NomeScript, N'Gestione completa delle distinte base e relativi allegati.', @ImprontaSha256);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
