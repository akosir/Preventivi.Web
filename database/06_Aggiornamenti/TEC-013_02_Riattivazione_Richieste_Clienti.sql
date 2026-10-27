/*
    TEC-013 - Riattivazione Richieste Clienti
    Versione schema: 2026102701
    Prerequisito: versione 2026102602 (TEC-013).

    Lo script non contiene USE e deve essere eseguito sul database Preventivi
    dell'ambiente di destinazione dopo una copia di sicurezza verificata.
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID(N'dbo.VersioniSchema', N'U') IS NULL
        THROW 52596, 'TEC-013-RIATTIVA: registro VersioniSchema non disponibile.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.VersioniSchema
        WHERE Versione = 2026102602
          AND CodiceIntervento = N'TEC-013'
    )
        THROW 52597, 'TEC-013-RIATTIVA: versione richiesta 2026102602 non installata.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.VersioniSchema
        WHERE Versione > 2026102602
          AND Versione <> 2026102701
    )
        THROW 52598, 'TEC-013-RIATTIVA: il database contiene una versione successiva non riconosciuta.', 1;

    IF OBJECT_ID(N'dbo.RichiesteClienti', N'U') IS NULL
       OR COL_LENGTH(N'dbo.RichiesteClienti', N'VersioneRiga') IS NULL
        THROW 52599, 'TEC-013-RIATTIVA: struttura RichiesteClienti non disponibile.', 1;

    /* PAYLOAD TEC-013-RIATTIVA START */
    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.RichiesteClienti_Riattiva
        @IdRichiestaCliente INT,
        @VersioneRiga BINARY(8),
        @Utente NVARCHAR(256)
    AS
    BEGIN
        SET NOCOUNT ON;

        IF NULLIF(LTRIM(RTRIM(@Utente)), N'''') IS NULL
            THROW 52500, ''Utente non disponibile.'', 1;

        DECLARE @StatoCorrente NVARCHAR(30);
        DECLARE @VersioneCorrente BINARY(8);

        SELECT
            @StatoCorrente = Stato,
            @VersioneCorrente = VersioneRiga
        FROM dbo.RichiesteClienti
        WHERE IdRichiestaCliente = @IdRichiestaCliente;

        IF @StatoCorrente IS NULL
            THROW 52505, ''Richiesta cliente non trovata.'', 1;

        IF @VersioneCorrente <> @VersioneRiga
            THROW 52506, ''La richiesta e stata modificata da un altro utente.'', 1;

        IF @StatoCorrente <> N''Annullata''
            THROW 52511, ''Solo una richiesta annullata puo essere riattivata.'', 1;

        UPDATE dbo.RichiesteClienti
        SET Stato = N''Nuova'',
            DataChiusura = NULL,
            DataModifica = SYSDATETIME(),
            UtenteModifica = LTRIM(RTRIM(@Utente))
        WHERE IdRichiestaCliente = @IdRichiestaCliente
          AND Stato = N''Annullata''
          AND VersioneRiga = @VersioneRiga;

        IF @@ROWCOUNT = 0
            THROW 52506, ''La richiesta e stata modificata da un altro utente.'', 1;
    END;';
    /* PAYLOAD TEC-013-RIATTIVA END */

    DECLARE @Versione INT = 2026102701;
    DECLARE @CodiceIntervento NVARCHAR(50) = N'TEC-013-RIATTIVA';
    DECLARE @NomeScript NVARCHAR(260) = N'TEC-013_02_Riattivazione_Richieste_Clienti.sql';
    -- SHA-256 del contenuto fra i marcatori PAYLOAD inclusi, normalizzato con LF.
    DECLARE @ImprontaSha256 CHAR(64) =
        'CBE9C760F2F8CC394ECBF479A3C38B9E841B0A00ECD016B5E473EA4C821A2011';

    IF EXISTS
    (
        SELECT 1
        FROM dbo.VersioniSchema
        WHERE Versione = @Versione
          AND CodiceIntervento = @CodiceIntervento
          AND NomeScript = @NomeScript
          AND ImprontaSha256 = @ImprontaSha256
    )
    BEGIN
        COMMIT TRANSACTION;
        RETURN;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.VersioniSchema
        WHERE Versione = @Versione
           OR CodiceIntervento = @CodiceIntervento
           OR NomeScript = @NomeScript
    )
        THROW 52600, 'TEC-013-RIATTIVA: versione gia registrata con dati o impronta differenti.', 1;

    INSERT INTO dbo.VersioniSchema
    (
        Versione,
        CodiceIntervento,
        NomeScript,
        Descrizione,
        ImprontaSha256
    )
    VALUES
    (
        @Versione,
        @CodiceIntervento,
        @NomeScript,
        N'Riattivazione controllata delle richieste clienti annullate.',
        @ImprontaSha256
    );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
