/*
    TEC-012 - Versionamento esplicito dello schema database

    Versione iniziale: 2026102601
    Stato rappresentato: aggiornamenti applicativi verificati fino a TEC-010.

    Lo script non contiene USE, non esegue aggiornamenti applicativi precedenti
    e si interrompe se non riconosce lo schema richiesto.
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;

BEGIN TRY
    BEGIN TRANSACTION;

    /* PAYLOAD TEC-012 START */
    DECLARE @OggettiMancanti TABLE
    (
        NomeOggetto NVARCHAR(256) NOT NULL
    );

    IF OBJECT_ID(N'dbo.Preventivi', N'U') IS NULL
        INSERT INTO @OggettiMancanti VALUES (N'dbo.Preventivi');
    IF OBJECT_ID(N'dbo.PreventiviRighe', N'U') IS NULL
        INSERT INTO @OggettiMancanti VALUES (N'dbo.PreventiviRighe');
    IF OBJECT_ID(N'dbo.ModelliPreventivo', N'U') IS NULL
        INSERT INTO @OggettiMancanti VALUES (N'dbo.ModelliPreventivo');
    IF OBJECT_ID(N'dbo.ModelliPreventivoRighe', N'U') IS NULL
        INSERT INTO @OggettiMancanti VALUES (N'dbo.ModelliPreventivoRighe');
    IF COL_LENGTH(N'dbo.ModelliPreventivoRighe', N'IdTipoRiga') IS NULL
        INSERT INTO @OggettiMancanti VALUES (N'dbo.ModelliPreventivoRighe.IdTipoRiga');
    IF OBJECT_ID(N'dbo.Sicurezza_UtenteAccesso_Get', N'P') IS NULL
        INSERT INTO @OggettiMancanti VALUES (N'dbo.Sicurezza_UtenteAccesso_Get');
    IF OBJECT_ID(N'dbo.Preventivi_Righe_Componenti_Crea', N'P') IS NULL
        INSERT INTO @OggettiMancanti VALUES (N'dbo.Preventivi_Righe_Componenti_Crea');
    IF OBJECT_ID(N'dbo.Preventivi_Eliminazione_Conferma', N'P') IS NULL
        INSERT INTO @OggettiMancanti VALUES (N'dbo.Preventivi_Eliminazione_Conferma');
    IF OBJECT_ID(N'dbo.Preventivi_Crea', N'P') IS NULL
        INSERT INTO @OggettiMancanti VALUES (N'dbo.Preventivi_Crea');
    IF OBJECT_ID(N'dbo.Preventivi_Varianti_Elimina', N'P') IS NULL
        INSERT INTO @OggettiMancanti VALUES (N'dbo.Preventivi_Varianti_Elimina');
    IF OBJECT_ID(N'dbo.sp_RicalcolaTotaliPreventivo', N'P') IS NULL
        INSERT INTO @OggettiMancanti VALUES (N'dbo.sp_RicalcolaTotaliPreventivo');
    IF OBJECT_ID(N'dbo.Preventivi_Modelli_Righe_Elimina', N'P') IS NULL
        INSERT INTO @OggettiMancanti VALUES (N'dbo.Preventivi_Modelli_Righe_Elimina');

    IF EXISTS (SELECT 1 FROM @OggettiMancanti)
    BEGIN
        DECLARE @ElencoMancanti NVARCHAR(1800);
        SELECT @ElencoMancanti = STRING_AGG(NomeOggetto, N', ')
        FROM @OggettiMancanti;

        DECLARE @MessaggioMancanti NVARCHAR(2048) =
            N'TEC-012: schema non allineato fino a TEC-010. Oggetti mancanti: '
            + @ElencoMancanti;
        THROW 52300, @MessaggioMancanti, 1;
    END;

    IF OBJECT_ID(N'dbo.VersioniSchema', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.VersioniSchema
        (
            Versione INT NOT NULL,
            CodiceIntervento NVARCHAR(50) NOT NULL,
            NomeScript NVARCHAR(260) NOT NULL,
            Descrizione NVARCHAR(500) NOT NULL,
            ImprontaSha256 CHAR(64) NOT NULL,
            DataApplicazioneUtc DATETIME2(0) NOT NULL
                CONSTRAINT DF_VersioniSchema_DataApplicazioneUtc
                DEFAULT SYSUTCDATETIME(),
            ApplicatoDa SYSNAME NOT NULL
                CONSTRAINT DF_VersioniSchema_ApplicatoDa
                DEFAULT ORIGINAL_LOGIN(),
            CONSTRAINT PK_VersioniSchema PRIMARY KEY (Versione),
            CONSTRAINT UQ_VersioniSchema_CodiceIntervento
                UNIQUE (CodiceIntervento),
            CONSTRAINT UQ_VersioniSchema_NomeScript UNIQUE (NomeScript),
            CONSTRAINT CK_VersioniSchema_Versione CHECK (Versione > 0),
            CONSTRAINT CK_VersioniSchema_Impronta
                CHECK (LEN(ImprontaSha256) = 64)
        );
    END;

    IF COL_LENGTH(N'dbo.VersioniSchema', N'Versione') IS NULL
       OR COL_LENGTH(N'dbo.VersioniSchema', N'CodiceIntervento') IS NULL
       OR COL_LENGTH(N'dbo.VersioniSchema', N'NomeScript') IS NULL
       OR COL_LENGTH(N'dbo.VersioniSchema', N'Descrizione') IS NULL
       OR COL_LENGTH(N'dbo.VersioniSchema', N'ImprontaSha256') IS NULL
       OR COL_LENGTH(N'dbo.VersioniSchema', N'DataApplicazioneUtc') IS NULL
       OR COL_LENGTH(N'dbo.VersioniSchema', N'ApplicatoDa') IS NULL
    BEGIN
        THROW 52301, 'TEC-012: la tabella VersioniSchema esiste con una struttura non compatibile.', 1;
    END;

    EXEC sys.sp_executesql N'
        CREATE OR ALTER TRIGGER dbo.TR_VersioniSchema_AppendOnly
        ON dbo.VersioniSchema
        INSTEAD OF UPDATE, DELETE
        AS
        BEGIN
            SET NOCOUNT ON;
            THROW 52302, ''Il registro VersioniSchema non consente modifiche o eliminazioni.'', 1;
        END;';

    EXEC sys.sp_executesql N'
        CREATE OR ALTER PROCEDURE dbo.Sistema_VersioneSchema_Corrente
        AS
        BEGIN
            SET NOCOUNT ON;

            SELECT TOP (1)
                Versione,
                CodiceIntervento,
                NomeScript,
                Descrizione,
                ImprontaSha256,
                DataApplicazioneUtc,
                ApplicatoDa
            FROM dbo.VersioniSchema
            ORDER BY Versione DESC;
        END;';
    /* PAYLOAD TEC-012 END */

    DECLARE @Versione INT = 2026102601;
    DECLARE @CodiceIntervento NVARCHAR(50) = N'TEC-012-BASELINE';
    DECLARE @NomeScript NVARCHAR(260) =
        N'TEC-012_01_Versionamento_Database.sql';
    -- SHA-256 del contenuto fra i marcatori PAYLOAD, normalizzato con LF.
    DECLARE @ImprontaSha256 CHAR(64) =
        'F25A17C8E377B059763945748878B836BA79580772E9484227E3EBEB7DAD40FF';

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
    BEGIN
        THROW 52303, 'TEC-012: versione gia registrata con dati o impronta differenti.', 1;
    END;

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
        N'Baseline applicativa verificata successiva a TEC-010.',
        @ImprontaSha256
    );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
