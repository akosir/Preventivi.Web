/*
    TEC-009 - Selezione atomica delle varianti

    Prerequisito:
    - TEC-009_03_Ricalcolo_Economico.sql applicato.

    Decisione 174:
    - una nuova selezione sostituisce quella precedente;
    - puo non esistere alcuna variante selezionata;
    - selezione ed eliminazione ricalcolano subito la testata.

    Lo script non seleziona il database.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.sp_RicalcolaTotaliVariante', N'P') IS NULL
   OR OBJECT_ID(N'dbo.sp_RicalcolaTotaliPreventivo', N'P') IS NULL
BEGIN
    THROW 51951, 'TEC-009: applicare prima lo script 03 di ricalcolo economico.', 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Varianti_Crea
    @IdPreventivo INT,
    @CodiceVariante NVARCHAR(60),
    @DescrizioneVariante NVARCHAR(500),
    @Note NVARCHAR(MAX) = NULL,
    @VarianteScelta BIT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @IdVariantePreventivo INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Preventivi
            WHERE IdPreventivo = @IdPreventivo
        )
        BEGIN
            THROW 51952, 'Preventivo non trovato.', 1;
        END;

        IF @VarianteScelta = 1
        BEGIN
            UPDATE dbo.PreventiviVarianti
            SET VarianteScelta = 0,
                DataModifica = SYSDATETIME()
            WHERE IdPreventivo = @IdPreventivo
              AND Attiva = 1
              AND VarianteScelta = 1;
        END;

        INSERT INTO dbo.PreventiviVarianti
        (
            IdPreventivo,
            CodiceVariante,
            DescrizioneVariante,
            Note,
            VarianteScelta,
            Attiva,
            TotaleCosti,
            TotaleVendita,
            MargineValore,
            MarginePerc,
            DataCreazione
        )
        VALUES
        (
            @IdPreventivo,
            @CodiceVariante,
            @DescrizioneVariante,
            @Note,
            @VarianteScelta,
            1,
            0,
            0,
            0,
            0,
            SYSDATETIME()
        );

        SET @IdVariantePreventivo = CONVERT(INT, SCOPE_IDENTITY());

        EXEC dbo.sp_RicalcolaTotaliVariante
            @IdVariantePreventivo = @IdVariantePreventivo;

        EXEC dbo.sp_RicalcolaTotaliPreventivo
            @IdPreventivo = @IdPreventivo;

        COMMIT TRANSACTION;

        SELECT @IdVariantePreventivo;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Varianti_Seleziona
    @IdVariantePreventivo INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @IdPreventivo INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @IdPreventivo = IdPreventivo
        FROM dbo.PreventiviVarianti
        WHERE IdVariantePreventivo = @IdVariantePreventivo
          AND Attiva = 1;

        IF @IdPreventivo IS NULL
        BEGIN
            THROW 51953, 'Variante preventivo non trovata o non attiva.', 1;
        END;

        UPDATE dbo.PreventiviVarianti
        SET VarianteScelta =
                CASE
                    WHEN IdVariantePreventivo = @IdVariantePreventivo THEN 1
                    ELSE 0
                END,
            DataModifica = SYSDATETIME()
        WHERE IdPreventivo = @IdPreventivo
          AND Attiva = 1;

        EXEC dbo.sp_RicalcolaTotaliVariante
            @IdVariantePreventivo = @IdVariantePreventivo;

        EXEC dbo.sp_RicalcolaTotaliPreventivo
            @IdPreventivo = @IdPreventivo;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Varianti_Elimina
    @IdVariantePreventivo INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @IdPreventivo INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @IdPreventivo = IdPreventivo
        FROM dbo.PreventiviVarianti
        WHERE IdVariantePreventivo = @IdVariantePreventivo
          AND Attiva = 1;

        IF @IdPreventivo IS NULL
        BEGIN
            THROW 51954, 'Variante preventivo non trovata o non attiva.', 1;
        END;

        UPDATE dbo.PreventiviVarianti
        SET VarianteScelta = 0,
            Attiva = 0,
            DataModifica = SYSDATETIME()
        WHERE IdVariantePreventivo = @IdVariantePreventivo;

        EXEC dbo.sp_RicalcolaTotaliPreventivo
            @IdPreventivo = @IdPreventivo;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        THROW;
    END CATCH;
END;
GO
