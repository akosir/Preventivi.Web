-- Decisione 335: identità dei nodi fra revisioni dello stesso articolo.
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @Versione INT = 2026111301;
    DECLARE @Codice NVARCHAR(50) = N'TEC-016-CONTINUITA-NODI';
    DECLARE @Script NVARCHAR(260) = N'TEC-016_08_Continuita_Nodi.sql';
    DECLARE @Impronta CHAR(64) = 'C2ADFF2BF4B8A9E3E2CAD1F31277CC26D8CB327A910D1668EE7BF33C2B4EBD6C';

    IF NOT EXISTS
       (SELECT 1 FROM dbo.VersioniSchema WITH (UPDLOCK, HOLDLOCK)
        WHERE Versione = 2026111203 AND CodiceIntervento = N'TEC-016-DISTINTE-IMPORTAZIONE')
        THROW 53890, 'Versione prerequisito 2026111203 non installata.', 1;

    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione > @Versione)
        THROW 53891, 'Il database contiene una versione successiva.', 1;

    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione = @Versione
               AND CodiceIntervento = @Codice AND NomeScript = @Script AND ImprontaSha256 = @Impronta)
    BEGIN
        COMMIT TRANSACTION;
        RETURN;
    END;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione = @Versione
               OR CodiceIntervento = @Codice OR NomeScript = @Script)
        THROW 53892, 'Versione gia registrata con metadati differenti.', 1;

/* PAYLOAD TEC-016-CONTINUITA-NODI START */
    IF COL_LENGTH(N'dbo.DistintaBaseNodi', N'ChiaveContinuita') IS NULL
        EXEC sys.sp_executesql N'
        ALTER TABLE dbo.DistintaBaseNodi ADD ChiaveContinuita UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT DF_DistintaBaseNodi_ChiaveContinuita DEFAULT NEWID();
        CREATE UNIQUE INDEX UX_DistintaBaseNodi_Continuita
            ON dbo.DistintaBaseNodi(IdRevisioneDistinta, ChiaveContinuita);';

        EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Nodi_Crea
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
/* PAYLOAD TEC-016-CONTINUITA-NODI END */

    INSERT dbo.VersioniSchema (Versione, CodiceIntervento, NomeScript, Descrizione, ImprontaSha256)
    VALUES (@Versione, @Codice, @Script, N'Identita dei nodi nelle revisioni della stessa distinta.', @Impronta);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
