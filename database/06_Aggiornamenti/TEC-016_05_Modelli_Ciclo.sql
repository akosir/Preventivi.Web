/*
    TEC-016 - Gestione modelli ciclo
    Versione schema: 2026111201
    Prerequisito: versione 2026110501 (TEC-016-DISTINTE-BASE).

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
        THROW 53540, 'TEC-016-MODELLI-CICLO: registro VersioniSchema non disponibile.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione = 2026110501 AND CodiceIntervento = N'TEC-016-DISTINTE-BASE')
        THROW 53541, 'TEC-016-MODELLI-CICLO: versione richiesta 2026110501 non installata.', 1;

    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione > 2026110501 AND Versione <> 2026111201)
        THROW 53542, 'TEC-016-MODELLI-CICLO: il database contiene una versione successiva non riconosciuta.', 1;

    IF OBJECT_ID(N'dbo.ModelliCiclo', N'U') IS NULL
       OR OBJECT_ID(N'dbo.ModelliCicloRighe', N'U') IS NULL
       OR OBJECT_ID(N'dbo.Lavorazioni', N'U') IS NULL
       OR OBJECT_ID(N'dbo.DistintaLavorazioni', N'U') IS NULL
       OR OBJECT_ID(N'dbo.ModelliPreventivoRighe', N'U') IS NULL
       OR OBJECT_ID(N'dbo.PreventiviRighe', N'U') IS NULL
       OR OBJECT_ID(N'dbo.Allegati', N'U') IS NULL
        THROW 53543, 'TEC-016-MODELLI-CICLO: tabelle richieste non disponibili.', 1;

    /* PAYLOAD TEC-016-MODELLI-CICLO START */
    IF EXISTS
    (
        SELECT 1 FROM dbo.ModelliCicloRighe
        WHERE RigaNr <= 0 OR Sequenza <= 0 OR TempoSetupMin < 0
           OR TempoPezzoMin < 0 OR CostoOrario < 0 OR CostoFisso < 0
    )
        THROW 53544, 'TEC-016-MODELLI-CICLO: presenti righe con tempi, costi o ordinamento non validi.', 1;

    IF COL_LENGTH(N'dbo.ModelliCiclo', N'UtenteCreazione') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.ModelliCiclo ADD UtenteCreazione NVARCHAR(256) NULL;';
    IF COL_LENGTH(N'dbo.ModelliCiclo', N'UtenteModifica') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.ModelliCiclo ADD UtenteModifica NVARCHAR(256) NULL;';
    IF COL_LENGTH(N'dbo.ModelliCiclo', N'VersioneRiga') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.ModelliCiclo ADD VersioneRiga ROWVERSION NOT NULL;';

    EXEC sys.sp_executesql N'
        UPDATE dbo.ModelliCiclo
        SET UtenteCreazione = COALESCE(UtenteCreazione, N''MIGRAZIONE-TEC-016'');
        ALTER TABLE dbo.ModelliCiclo ALTER COLUMN UtenteCreazione NVARCHAR(256) NOT NULL;';

    IF NOT EXISTS
    (
        SELECT 1 FROM sys.default_constraints
        WHERE parent_object_id = OBJECT_ID(N'dbo.ModelliCiclo')
          AND parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'dbo.ModelliCiclo'), N'UtenteCreazione', 'ColumnId')
    )
        ALTER TABLE dbo.ModelliCiclo ADD CONSTRAINT DF_ModelliCiclo_UtenteCreazione DEFAULT (N'SISTEMA') FOR UtenteCreazione;

    IF COL_LENGTH(N'dbo.ModelliCicloRighe', N'DataCreazione') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.ModelliCicloRighe ADD DataCreazione DATETIME2(0) NULL;';
    IF COL_LENGTH(N'dbo.ModelliCicloRighe', N'DataModifica') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.ModelliCicloRighe ADD DataModifica DATETIME2(0) NULL;';
    IF COL_LENGTH(N'dbo.ModelliCicloRighe', N'UtenteCreazione') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.ModelliCicloRighe ADD UtenteCreazione NVARCHAR(256) NULL;';
    IF COL_LENGTH(N'dbo.ModelliCicloRighe', N'UtenteModifica') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.ModelliCicloRighe ADD UtenteModifica NVARCHAR(256) NULL;';
    IF COL_LENGTH(N'dbo.ModelliCicloRighe', N'VersioneRiga') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.ModelliCicloRighe ADD VersioneRiga ROWVERSION NOT NULL;';

    EXEC sys.sp_executesql N'
        UPDATE dbo.ModelliCicloRighe
        SET DataCreazione = COALESCE(DataCreazione, SYSDATETIME()),
            UtenteCreazione = COALESCE(UtenteCreazione, N''MIGRAZIONE-TEC-016'');
        ALTER TABLE dbo.ModelliCicloRighe ALTER COLUMN DataCreazione DATETIME2(0) NOT NULL;
        ALTER TABLE dbo.ModelliCicloRighe ALTER COLUMN UtenteCreazione NVARCHAR(256) NOT NULL;';

    IF NOT EXISTS
    (
        SELECT 1 FROM sys.default_constraints
        WHERE parent_object_id = OBJECT_ID(N'dbo.ModelliCicloRighe')
          AND parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'dbo.ModelliCicloRighe'), N'DataCreazione', 'ColumnId')
    )
        ALTER TABLE dbo.ModelliCicloRighe ADD CONSTRAINT DF_ModelliCicloRighe_DataCreazione DEFAULT (SYSDATETIME()) FOR DataCreazione;

    IF NOT EXISTS
    (
        SELECT 1 FROM sys.default_constraints
        WHERE parent_object_id = OBJECT_ID(N'dbo.ModelliCicloRighe')
          AND parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'dbo.ModelliCicloRighe'), N'UtenteCreazione', 'ColumnId')
    )
        ALTER TABLE dbo.ModelliCicloRighe ADD CONSTRAINT DF_ModelliCicloRighe_UtenteCreazione DEFAULT (N'SISTEMA') FOR UtenteCreazione;

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_ModelliCiclo_Elenco
        @Ricerca NVARCHAR(200) = NULL, @SoloAttivi BIT = NULL
    AS
    BEGIN
        SET NOCOUNT ON;
        SET @Ricerca = NULLIF(LTRIM(RTRIM(@Ricerca)), N'''');
        SELECT modello.IdModelloCiclo, modello.CodiceModelloCiclo,
               modello.Descrizione, COUNT(riga.IdRigaModelloCiclo) AS NumeroRighe,
               modello.Attivo
        FROM dbo.ModelliCiclo AS modello
        LEFT JOIN dbo.ModelliCicloRighe AS riga ON riga.IdModelloCiclo = modello.IdModelloCiclo
        WHERE (@SoloAttivi IS NULL OR modello.Attivo = @SoloAttivi)
          AND (@Ricerca IS NULL OR modello.CodiceModelloCiclo LIKE N''%'' + @Ricerca + N''%'' OR modello.Descrizione LIKE N''%'' + @Ricerca + N''%'')
        GROUP BY modello.IdModelloCiclo, modello.CodiceModelloCiclo, modello.Descrizione, modello.Attivo
        ORDER BY modello.CodiceModelloCiclo, modello.Descrizione;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_ModelliCiclo_Dettaglio @IdModelloCiclo INT
    AS
    BEGIN
        SET NOCOUNT ON;
        SELECT IdModelloCiclo, CodiceModelloCiclo, Descrizione, Attivo, Note,
               DataCreazione, DataModifica, UtenteCreazione, UtenteModifica, VersioneRiga
        FROM dbo.ModelliCiclo WHERE IdModelloCiclo = @IdModelloCiclo;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_ModelliCiclo_Crea
        @CodiceModelloCiclo NVARCHAR(50), @Descrizione NVARCHAR(150),
        @Note NVARCHAR(500) = NULL, @Utente NVARCHAR(256)
    AS
    BEGIN
        SET NOCOUNT ON; SET XACT_ABORT ON;
        SET @CodiceModelloCiclo = NULLIF(LTRIM(RTRIM(@CodiceModelloCiclo)), N'''');
        SET @Descrizione = NULLIF(LTRIM(RTRIM(@Descrizione)), N'''');
        SET @Note = NULLIF(LTRIM(RTRIM(@Note)), N''''); SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
        IF @CodiceModelloCiclo IS NULL OR @Descrizione IS NULL OR @Utente IS NULL THROW 53501, ''Dati modello ciclo non validi.'', 1;
        BEGIN TRANSACTION;
        IF EXISTS (SELECT 1 FROM dbo.ModelliCiclo WITH (UPDLOCK, HOLDLOCK) WHERE CodiceModelloCiclo = @CodiceModelloCiclo) THROW 53502, ''Codice modello ciclo gia utilizzato.'', 1;
        INSERT dbo.ModelliCiclo (CodiceModelloCiclo, Descrizione, Attivo, Note, DataCreazione, DataModifica, UtenteCreazione, UtenteModifica)
        VALUES (@CodiceModelloCiclo, @Descrizione, 1, @Note, SYSDATETIME(), NULL, @Utente, NULL);
        DECLARE @Id INT = CONVERT(INT, SCOPE_IDENTITY()); COMMIT TRANSACTION; SELECT @Id;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_ModelliCiclo_Aggiorna
        @IdModelloCiclo INT, @CodiceModelloCiclo NVARCHAR(50), @Descrizione NVARCHAR(150),
        @Note NVARCHAR(500) = NULL, @Utente NVARCHAR(256), @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON; SET XACT_ABORT ON;
        SET @CodiceModelloCiclo = NULLIF(LTRIM(RTRIM(@CodiceModelloCiclo)), N'''');
        SET @Descrizione = NULLIF(LTRIM(RTRIM(@Descrizione)), N'''');
        SET @Note = NULLIF(LTRIM(RTRIM(@Note)), N''''); SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
        IF @CodiceModelloCiclo IS NULL OR @Descrizione IS NULL OR @Utente IS NULL THROW 53501, ''Dati modello ciclo non validi.'', 1;
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.ModelliCiclo WITH (UPDLOCK, HOLDLOCK) WHERE IdModelloCiclo = @IdModelloCiclo) THROW 53503, ''Modello ciclo non trovato.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.ModelliCiclo WHERE IdModelloCiclo = @IdModelloCiclo AND VersioneRiga = @VersioneRiga) THROW 53504, ''Modello ciclo modificato da altro utente.'', 1;
        IF EXISTS (SELECT 1 FROM dbo.ModelliCiclo WHERE CodiceModelloCiclo = @CodiceModelloCiclo AND IdModelloCiclo <> @IdModelloCiclo) THROW 53502, ''Codice modello ciclo gia utilizzato.'', 1;
        UPDATE dbo.ModelliCiclo SET CodiceModelloCiclo=@CodiceModelloCiclo, Descrizione=@Descrizione, Note=@Note,
            DataModifica=SYSDATETIME(), UtenteModifica=@Utente
        WHERE IdModelloCiclo=@IdModelloCiclo AND VersioneRiga=@VersioneRiga;
        IF @@ROWCOUNT = 0 THROW 53504, ''Modello ciclo modificato da altro utente.'', 1;
        COMMIT TRANSACTION;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_ModelliCiclo_ImpostaStato
        @IdModelloCiclo INT, @Attivo BIT, @Utente NVARCHAR(256), @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON; SET XACT_ABORT ON; SET @Utente=NULLIF(LTRIM(RTRIM(@Utente)),N'''');
        IF @Utente IS NULL THROW 53501, ''Utente non valido.'', 1;
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.ModelliCiclo WITH (UPDLOCK, HOLDLOCK) WHERE IdModelloCiclo=@IdModelloCiclo) THROW 53503, ''Modello ciclo non trovato.'', 1;
        UPDATE dbo.ModelliCiclo SET Attivo=@Attivo, DataModifica=SYSDATETIME(), UtenteModifica=@Utente
        WHERE IdModelloCiclo=@IdModelloCiclo AND VersioneRiga=@VersioneRiga;
        IF @@ROWCOUNT=0 THROW 53504, ''Modello ciclo modificato da altro utente.'', 1;
        COMMIT TRANSACTION;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_ModelliCiclo_Elimina
        @IdModelloCiclo INT, @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON; SET XACT_ABORT ON; BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.ModelliCiclo WITH (UPDLOCK, HOLDLOCK) WHERE IdModelloCiclo=@IdModelloCiclo) THROW 53503, ''Modello ciclo non trovato.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.ModelliCiclo WHERE IdModelloCiclo=@IdModelloCiclo AND VersioneRiga=@VersioneRiga) THROW 53504, ''Modello ciclo modificato da altro utente.'', 1;
        IF EXISTS (SELECT 1 FROM dbo.ModelliCicloRighe WHERE IdModelloCiclo=@IdModelloCiclo)
           OR EXISTS (SELECT 1 FROM dbo.DistintaLavorazioni WHERE IdModelloCiclo=@IdModelloCiclo)
           OR EXISTS (SELECT 1 FROM dbo.ModelliPreventivoRighe WHERE IdModelloCiclo=@IdModelloCiclo)
           OR EXISTS (SELECT 1 FROM dbo.PreventiviRighe WHERE IdModelloCiclo=@IdModelloCiclo)
           OR EXISTS (SELECT 1 FROM dbo.Allegati WHERE Entita=N''ModelliCiclo'' AND IdEntita=@IdModelloCiclo)
            THROW 53505, ''Modello ciclo utilizzato o contenente dati collegati.'', 1;
        DELETE dbo.ModelliCiclo WHERE IdModelloCiclo=@IdModelloCiclo AND VersioneRiga=@VersioneRiga;
        COMMIT TRANSACTION;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_ModelliCiclo_Lavorazioni_Lookup @IdCorrente INT = NULL
    AS
    BEGIN
        SET NOCOUNT ON;
        SELECT IdLavorazione, CodiceLavorazione, Descrizione, CostoOrarioStandard,
               TempoSetupMinDefault, TempoPezzoMinDefault, Attiva
        FROM dbo.Lavorazioni WHERE Attiva=1 OR IdLavorazione=@IdCorrente
        ORDER BY CodiceLavorazione, Descrizione;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_ModelliCiclo_Righe_Elenco @IdModelloCiclo INT
    AS
    BEGIN
        SET NOCOUNT ON;
        SELECT r.IdRigaModelloCiclo, r.RigaNr, r.Sequenza, r.IdLavorazione,
               l.CodiceLavorazione, l.Descrizione AS DescrizioneLavorazione,
               r.TempoSetupMin, r.TempoPezzoMin, r.CostoOrario, r.CostoFisso
        FROM dbo.ModelliCicloRighe r INNER JOIN dbo.Lavorazioni l ON l.IdLavorazione=r.IdLavorazione
        WHERE r.IdModelloCiclo=@IdModelloCiclo ORDER BY r.Sequenza, r.RigaNr;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_ModelliCiclo_Righe_Dettaglio @IdRigaModelloCiclo INT
    AS
    BEGIN
        SET NOCOUNT ON;
        SELECT r.IdRigaModelloCiclo, r.IdModelloCiclo, r.RigaNr, r.Sequenza, r.IdLavorazione,
               l.CodiceLavorazione, l.Descrizione AS DescrizioneLavorazione,
               r.TempoSetupMin, r.TempoPezzoMin, r.CostoOrario, r.CostoFisso, r.Note,
               r.DataCreazione, r.DataModifica, r.UtenteCreazione, r.UtenteModifica, r.VersioneRiga
        FROM dbo.ModelliCicloRighe r INNER JOIN dbo.Lavorazioni l ON l.IdLavorazione=r.IdLavorazione
        WHERE r.IdRigaModelloCiclo=@IdRigaModelloCiclo;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_ModelliCiclo_Righe_Crea
        @IdModelloCiclo INT, @RigaNr INT, @Sequenza INT, @IdLavorazione INT,
        @TempoSetupMin DECIMAL(18,2), @TempoPezzoMin DECIMAL(18,4),
        @CostoOrario DECIMAL(18,4), @CostoFisso DECIMAL(18,4),
        @Note NVARCHAR(500)=NULL, @Utente NVARCHAR(256)
    AS
    BEGIN
        SET NOCOUNT ON; SET XACT_ABORT ON; SET @Note=NULLIF(LTRIM(RTRIM(@Note)),N''''); SET @Utente=NULLIF(LTRIM(RTRIM(@Utente)),N'''');
        IF @RigaNr<=0 OR @Sequenza<=0 OR @TempoSetupMin<0 OR @TempoPezzoMin<0 OR @CostoOrario<0 OR @CostoFisso<0 OR @Utente IS NULL THROW 53501, ''Dati riga modello ciclo non validi.'', 1;
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.ModelliCiclo WITH (UPDLOCK,HOLDLOCK) WHERE IdModelloCiclo=@IdModelloCiclo AND Attivo=1) THROW 53506, ''Modello ciclo non attivo.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.Lavorazioni WHERE IdLavorazione=@IdLavorazione AND Attiva=1) THROW 53507, ''Lavorazione non valida o non attiva.'', 1;
        IF EXISTS (SELECT 1 FROM dbo.ModelliCicloRighe WITH (UPDLOCK,HOLDLOCK) WHERE IdModelloCiclo=@IdModelloCiclo AND RigaNr=@RigaNr) THROW 53508, ''Numero riga gia utilizzato.'', 1;
        INSERT dbo.ModelliCicloRighe (IdModelloCiclo,RigaNr,IdLavorazione,Sequenza,TempoSetupMin,TempoPezzoMin,CostoOrario,CostoFisso,Note,DataCreazione,DataModifica,UtenteCreazione,UtenteModifica)
        VALUES (@IdModelloCiclo,@RigaNr,@IdLavorazione,@Sequenza,@TempoSetupMin,@TempoPezzoMin,@CostoOrario,@CostoFisso,@Note,SYSDATETIME(),NULL,@Utente,NULL);
        DECLARE @Id INT=CONVERT(INT,SCOPE_IDENTITY()); COMMIT TRANSACTION; SELECT @Id;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_ModelliCiclo_Righe_Aggiorna
        @IdRigaModelloCiclo INT, @IdModelloCiclo INT, @RigaNr INT, @Sequenza INT, @IdLavorazione INT,
        @TempoSetupMin DECIMAL(18,2), @TempoPezzoMin DECIMAL(18,4), @CostoOrario DECIMAL(18,4), @CostoFisso DECIMAL(18,4),
        @Note NVARCHAR(500)=NULL, @Utente NVARCHAR(256), @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON; SET XACT_ABORT ON; SET @Note=NULLIF(LTRIM(RTRIM(@Note)),N''''); SET @Utente=NULLIF(LTRIM(RTRIM(@Utente)),N'''');
        IF @RigaNr<=0 OR @Sequenza<=0 OR @TempoSetupMin<0 OR @TempoPezzoMin<0 OR @CostoOrario<0 OR @CostoFisso<0 OR @Utente IS NULL THROW 53501, ''Dati riga modello ciclo non validi.'', 1;
        BEGIN TRANSACTION; DECLARE @IdLavorazioneCorrente INT;
        SELECT @IdLavorazioneCorrente=IdLavorazione FROM dbo.ModelliCicloRighe WITH (UPDLOCK,HOLDLOCK) WHERE IdRigaModelloCiclo=@IdRigaModelloCiclo AND IdModelloCiclo=@IdModelloCiclo;
        IF @IdLavorazioneCorrente IS NULL THROW 53509, ''Riga modello ciclo non trovata.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.ModelliCicloRighe WHERE IdRigaModelloCiclo=@IdRigaModelloCiclo AND VersioneRiga=@VersioneRiga) THROW 53510, ''Riga modificata da altro utente.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.Lavorazioni WHERE IdLavorazione=@IdLavorazione AND (Attiva=1 OR IdLavorazione=@IdLavorazioneCorrente)) THROW 53507, ''Lavorazione non valida.'', 1;
        IF EXISTS (SELECT 1 FROM dbo.ModelliCicloRighe WHERE IdModelloCiclo=@IdModelloCiclo AND RigaNr=@RigaNr AND IdRigaModelloCiclo<>@IdRigaModelloCiclo) THROW 53508, ''Numero riga gia utilizzato.'', 1;
        UPDATE dbo.ModelliCicloRighe SET RigaNr=@RigaNr,Sequenza=@Sequenza,IdLavorazione=@IdLavorazione,TempoSetupMin=@TempoSetupMin,TempoPezzoMin=@TempoPezzoMin,
            CostoOrario=@CostoOrario,CostoFisso=@CostoFisso,Note=@Note,DataModifica=SYSDATETIME(),UtenteModifica=@Utente
        WHERE IdRigaModelloCiclo=@IdRigaModelloCiclo AND IdModelloCiclo=@IdModelloCiclo AND VersioneRiga=@VersioneRiga;
        IF @@ROWCOUNT=0 THROW 53510, ''Riga modificata da altro utente.'', 1; COMMIT TRANSACTION;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_ModelliCiclo_Righe_Elimina
        @IdRigaModelloCiclo INT, @IdModelloCiclo INT, @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON; SET XACT_ABORT ON; BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.ModelliCicloRighe WITH (UPDLOCK,HOLDLOCK) WHERE IdRigaModelloCiclo=@IdRigaModelloCiclo AND IdModelloCiclo=@IdModelloCiclo) THROW 53509, ''Riga modello ciclo non trovata.'', 1;
        DELETE dbo.ModelliCicloRighe WHERE IdRigaModelloCiclo=@IdRigaModelloCiclo AND IdModelloCiclo=@IdModelloCiclo AND VersioneRiga=@VersioneRiga;
        IF @@ROWCOUNT=0 THROW 53510, ''Riga modificata da altro utente.'', 1; COMMIT TRANSACTION;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.ModelliCiclo_Lookup
    AS
    BEGIN
        SET NOCOUNT ON;
        SELECT IdModelloCiclo, CodiceModelloCiclo, Descrizione
        FROM dbo.ModelliCiclo WHERE Attivo=1 ORDER BY CodiceModelloCiclo, Descrizione;
    END;';
    /* PAYLOAD TEC-016-MODELLI-CICLO END */

    DECLARE @Versione INT = 2026111201;
    DECLARE @CodiceIntervento NVARCHAR(50) = N'TEC-016-MODELLI-CICLO';
    DECLARE @NomeScript NVARCHAR(260) = N'TEC-016_05_Modelli_Ciclo.sql';
    -- SHA-256 del contenuto fra i marcatori PAYLOAD inclusi, normalizzato con LF.
    DECLARE @ImprontaSha256 CHAR(64) = '3F42985B25F3509A0852F041799728CC3ED8BD7C1F2816E8447357587A163D1B';

    IF EXISTS
    (
        SELECT 1 FROM dbo.VersioniSchema
        WHERE Versione=@Versione AND CodiceIntervento=@CodiceIntervento
          AND NomeScript=@NomeScript AND ImprontaSha256=@ImprontaSha256
    )
    BEGIN COMMIT TRANSACTION; RETURN; END;

    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione=@Versione OR CodiceIntervento=@CodiceIntervento OR NomeScript=@NomeScript)
        THROW 53549, 'TEC-016-MODELLI-CICLO: versione gia registrata con dati o impronta differenti.', 1;

    INSERT dbo.VersioniSchema (Versione,CodiceIntervento,NomeScript,Descrizione,ImprontaSha256)
    VALUES (@Versione,@CodiceIntervento,@NomeScript,N'Gestione completa dei modelli ciclo e allegati di testata.',@ImprontaSha256);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
