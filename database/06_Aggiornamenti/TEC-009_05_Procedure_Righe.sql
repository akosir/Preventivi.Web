/*
    TEC-009 - Creazione ed eliminazione righe con totali calcolati

    Prerequisito:
    - TEC-009_03_Ricalcolo_Economico.sql applicato.

    Decisione 173:
    - TotaleCosti non e un dato manuale;
    - per righe strutturate nasce da materiali e lavorazioni;
    - per righe libere e Quantita * CostoUnitarioLibero.

    Lo script non seleziona il database.
*/

SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.sp_RicalcolaTotaliVariante', N'P') IS NULL
   OR OBJECT_ID(N'dbo.sp_RicalcolaTotaliPreventivo', N'P') IS NULL
BEGIN
    THROW 51941, 'TEC-009: applicare prima lo script 03 di ricalcolo economico.', 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.TipiRigaPreventivo_Elenco
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        IdTipoRiga,
        Codice,
        Descrizione,
        RigaLibera
    FROM dbo.TipiRigaPreventivo
    WHERE Attiva = 1
    ORDER BY Ordinamento, Descrizione;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_Crea
    @IdPreventivo INT,
    @RigaNr INT = NULL,
    @IdArticolo INT = NULL,
    @IdModelloCiclo INT = NULL,
    @DescrizioneVoce NVARCHAR(500),
    @Quantita DECIMAL(18,4),
    @PrezzoUnitarioVendita DECIMAL(18,4),
    @Note NVARCHAR(MAX) = NULL,
    @MarkupPerc DECIMAL(9,2),
    @PrezzoManuale BIT,
    @IdVariantePreventivo INT = NULL,
    @CostoUnitarioLibero DECIMAL(18,4) = NULL,
    @IdTipoRiga INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @NumeroRiga INT,
        @RigaLibera BIT,
        @TotaleCosti DECIMAL(18,2),
        @TotaleVendita DECIMAL(18,2),
        @MargineValore DECIMAL(18,2),
        @MarginePerc DECIMAL(9,2),
        @IdRigaPreventivo INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Preventivi
            WHERE IdPreventivo = @IdPreventivo
        )
        BEGIN
            THROW 51942, 'Preventivo non trovato.', 1;
        END;

        SELECT @RigaLibera = RigaLibera
        FROM dbo.TipiRigaPreventivo
        WHERE IdTipoRiga = @IdTipoRiga
          AND Attiva = 1;

        IF @RigaLibera IS NULL
        BEGIN
            THROW 51943, 'Tipo riga non trovato o non attivo.', 1;
        END;

        IF @IdVariantePreventivo IS NOT NULL
           AND NOT EXISTS
           (
               SELECT 1
               FROM dbo.PreventiviVarianti
               WHERE IdVariantePreventivo = @IdVariantePreventivo
                 AND IdPreventivo = @IdPreventivo
                 AND Attiva = 1
           )
        BEGIN
            THROW 51944, 'La variante non appartiene al preventivo o non e attiva.', 1;
        END;

        IF @Quantita <= 0
        BEGIN
            THROW 51945, 'La quantita deve essere maggiore di zero.', 1;
        END;

        IF @RigaLibera = 1 AND @CostoUnitarioLibero IS NULL
        BEGIN
            THROW 51946, 'La riga libera richiede il costo unitario libero.', 1;
        END;

        IF @RigaLibera = 0
        BEGIN
            SET @CostoUnitarioLibero = NULL;
            SET @TotaleCosti = 0;
        END
        ELSE
        BEGIN
            SET @TotaleCosti = ROUND(@Quantita * @CostoUnitarioLibero, 2);
        END;

        IF @PrezzoManuale = 1
        BEGIN
            SET @TotaleVendita = ROUND(@Quantita * @PrezzoUnitarioVendita, 2);
        END
        ELSE
        BEGIN
            SET @TotaleVendita =
                ROUND(@TotaleCosti * (1 + @MarkupPerc / 100.0), 2);

            SET @PrezzoUnitarioVendita =
                CASE
                    WHEN @Quantita = 0 THEN 0
                    ELSE ROUND(@TotaleVendita / @Quantita, 4)
                END;
        END;

        SET @MargineValore = @TotaleVendita - @TotaleCosti;
        SET @MarginePerc =
            CASE
                WHEN @TotaleVendita = 0 THEN 0
                ELSE ROUND((@MargineValore / @TotaleVendita) * 100, 2)
            END;

        SET @NumeroRiga =
            ISNULL
            (
                @RigaNr,
                ISNULL
                (
                    (
                        SELECT MAX(RigaNr)
                        FROM dbo.PreventiviRighe WITH (UPDLOCK, HOLDLOCK)
                        WHERE IdPreventivo = @IdPreventivo
                    ),
                    0
                ) + 1
            );

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
            DataCreazione,
            MarkupPerc,
            PrezzoManuale,
            IdVariantePreventivo,
            CostoUnitarioLibero,
            IdTipoRiga
        )
        VALUES
        (
            @IdPreventivo,
            @NumeroRiga,
            @IdArticolo,
            @IdModelloCiclo,
            @DescrizioneVoce,
            @Quantita,
            @PrezzoUnitarioVendita,
            @TotaleVendita,
            @TotaleCosti,
            @MargineValore,
            @MarginePerc,
            @Note,
            SYSDATETIME(),
            @MarkupPerc,
            @PrezzoManuale,
            @IdVariantePreventivo,
            @CostoUnitarioLibero,
            @IdTipoRiga
        );

        SET @IdRigaPreventivo = CONVERT(INT, SCOPE_IDENTITY());

        IF @IdVariantePreventivo IS NOT NULL
        BEGIN
            EXEC dbo.sp_RicalcolaTotaliVariante
                @IdVariantePreventivo = @IdVariantePreventivo;
        END;

        EXEC dbo.sp_RicalcolaTotaliPreventivo
            @IdPreventivo = @IdPreventivo;

        COMMIT TRANSACTION;

        SELECT @IdRigaPreventivo;
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

CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_Elimina
    @IdRigaPreventivo INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @IdPreventivo INT,
        @IdVariantePreventivo INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT
            @IdPreventivo = IdPreventivo,
            @IdVariantePreventivo = IdVariantePreventivo
        FROM dbo.PreventiviRighe
        WHERE IdRigaPreventivo = @IdRigaPreventivo;

        IF @IdPreventivo IS NULL
        BEGIN
            THROW 51947, 'Riga preventivo non trovata.', 1;
        END;

        DELETE FROM dbo.PreventiviRigheLavorazioni
        WHERE IdRigaPreventivo = @IdRigaPreventivo;

        DELETE FROM dbo.PreventiviRigheMateriali
        WHERE IdRigaPreventivo = @IdRigaPreventivo;

        DELETE FROM dbo.PreventiviRigheComponenti
        WHERE IdRigaPreventivo = @IdRigaPreventivo;

        DELETE FROM dbo.PreventiviRighe
        WHERE IdRigaPreventivo = @IdRigaPreventivo;

        IF @IdVariantePreventivo IS NOT NULL
        BEGIN
            EXEC dbo.sp_RicalcolaTotaliVariante
                @IdVariantePreventivo = @IdVariantePreventivo;
        END;

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
