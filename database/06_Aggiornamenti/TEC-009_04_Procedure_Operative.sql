/*
    TEC-009 - Procedure operative con ricalcolo atomico

    Prerequisito:
    - TEC-009_03_Ricalcolo_Economico.sql applicato.

    Lo script non seleziona il database.
*/

SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.sp_RicalcolaTotaliRigaPreventivo', N'P') IS NULL
   OR OBJECT_ID(N'dbo.sp_RicalcolaTotaliVariante', N'P') IS NULL
   OR OBJECT_ID(N'dbo.sp_RicalcolaTotaliPreventivo', N'P') IS NULL
BEGIN
    THROW 51931, 'TEC-009: applicare prima lo script 03 di ricalcolo economico.', 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_Componenti_Crea
    @IdRigaPreventivo INT,
    @IdRigaCompPrevPadre INT = NULL,
    @TipoOrigineComponente NVARCHAR(20),
    @IdArticoloOrigine INT = NULL,
    @IdNodoDistinta INT = NULL,
    @IdNodoPadre INT = NULL,
    @DescrizioneNodo NVARCHAR(400),
    @Livello INT,
    @QuantitaBase DECIMAL(18,4),
    @OrdineVisualizzazione INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @QuantitaRiga DECIMAL(18,4),
        @QuantitaPadre DECIMAL(18,4),
        @QuantitaCalcolata DECIMAL(18,4),
        @RigaLibera BIT,
        @IdRigaCompPrev INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT
            @QuantitaRiga = riga.Quantita,
            @RigaLibera = tipo.RigaLibera
        FROM dbo.PreventiviRighe AS riga
        INNER JOIN dbo.TipiRigaPreventivo AS tipo
            ON tipo.IdTipoRiga = riga.IdTipoRiga
        WHERE riga.IdRigaPreventivo = @IdRigaPreventivo;

        IF @QuantitaRiga IS NULL
        BEGIN
            THROW 51201, 'Riga preventivo non trovata.', 1;
        END;

        IF @RigaLibera = 1
        BEGIN
            THROW 51932, 'Una riga libera non puo contenere componenti.', 1;
        END;

        IF @QuantitaBase <= 0
        BEGIN
            THROW 51202, 'La quantita base deve essere maggiore di zero.', 1;
        END;

        IF @TipoOrigineComponente IS NULL
           OR @TipoOrigineComponente NOT IN (N'Distinta', N'Articolo', N'Libero')
           OR (@TipoOrigineComponente = N'Distinta' AND (@IdNodoDistinta IS NULL OR @IdArticoloOrigine IS NULL))
           OR (@TipoOrigineComponente = N'Articolo' AND (@IdNodoDistinta IS NOT NULL OR @IdArticoloOrigine IS NULL))
           OR (@TipoOrigineComponente = N'Libero' AND (@IdNodoDistinta IS NOT NULL OR @IdArticoloOrigine IS NOT NULL))
        BEGIN
            THROW 51203, 'Origine componente non coerente con articolo e nodo distinta.', 1;
        END;

        IF @Livello < 0
        BEGIN
            THROW 51206, 'Il livello del componente non puo essere negativo.', 1;
        END;

        IF @TipoOrigineComponente = N'Distinta'
           AND NOT EXISTS
           (
               SELECT 1
               FROM dbo.DistintaBaseNodi
               WHERE IdNodoDistinta = @IdNodoDistinta
                 AND IdArticolo = @IdArticoloOrigine
           )
        BEGIN
            THROW 51204, 'Il nodo distinta non appartiene all''articolo indicato.', 1;
        END;

        IF @IdRigaCompPrevPadre IS NOT NULL
        BEGIN
            SELECT @QuantitaPadre = QuantitaCalcolata
            FROM dbo.PreventiviRigheComponenti
            WHERE IdRigaCompPrev = @IdRigaCompPrevPadre
              AND IdRigaPreventivo = @IdRigaPreventivo;

            IF @QuantitaPadre IS NULL
            BEGIN
                THROW 51205, 'Il componente padre non appartiene alla riga indicata.', 1;
            END;
        END;

        SET @QuantitaCalcolata =
            CASE
                WHEN @IdRigaCompPrevPadre IS NULL THEN @QuantitaRiga * @QuantitaBase
                ELSE @QuantitaPadre * @QuantitaBase
            END;

        INSERT INTO dbo.PreventiviRigheComponenti
        (
            IdRigaPreventivo,
            IdRigaCompPrevPadre,
            TipoOrigineComponente,
            IdArticoloOrigine,
            IdNodoDistinta,
            IdNodoPadre,
            DescrizioneNodo,
            Livello,
            QuantitaBase,
            QuantitaCalcolata,
            OrdineVisualizzazione
        )
        VALUES
        (
            @IdRigaPreventivo,
            @IdRigaCompPrevPadre,
            @TipoOrigineComponente,
            @IdArticoloOrigine,
            @IdNodoDistinta,
            @IdNodoPadre,
            @DescrizioneNodo,
            @Livello,
            @QuantitaBase,
            @QuantitaCalcolata,
            ISNULL(@OrdineVisualizzazione, 10)
        );

        SET @IdRigaCompPrev = CONVERT(INT, SCOPE_IDENTITY());

        COMMIT TRANSACTION;

        SELECT @IdRigaCompPrev;
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

CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_Componenti_Elimina
    @IdRigaCompPrev INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @IdRigaPreventivo INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @IdRigaPreventivo = IdRigaPreventivo
        FROM dbo.PreventiviRigheComponenti
        WHERE IdRigaCompPrev = @IdRigaCompPrev;

        IF @IdRigaPreventivo IS NULL
        BEGIN
            THROW 51933, 'Componente preventivo non trovato.', 1;
        END;

        DELETE FROM dbo.PreventiviRigheLavorazioni
        WHERE IdRigaCompPrev = @IdRigaCompPrev;

        DELETE FROM dbo.PreventiviRigheMateriali
        WHERE IdRigaCompPrev = @IdRigaCompPrev;

        DELETE FROM dbo.PreventiviRigheComponenti
        WHERE IdRigaCompPrev = @IdRigaCompPrev;

        EXEC dbo.sp_RicalcolaTotaliRigaPreventivo
            @IdRigaPreventivo = @IdRigaPreventivo;

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

CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_Materiali_Crea
    @IdRigaPreventivo INT,
    @IdRigaCompPrev INT = NULL,
    @IdNodoDistinta INT = NULL,
    @IdMateriale INT = NULL,
    @DescrizioneMateriale NVARCHAR(400),
    @TipoMateriale NVARCHAR(60) = NULL,
    @UM NVARCHAR(20) = NULL,
    @Quantita DECIMAL(18,4),
    @CostoUnitario DECIMAL(18,4),
    @DaAcquistare BIT,
    @IdFornitoreSuggerito INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @IdRigaMatPrev INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.PreventiviRighe AS riga
            INNER JOIN dbo.TipiRigaPreventivo AS tipo
                ON tipo.IdTipoRiga = riga.IdTipoRiga
            WHERE riga.IdRigaPreventivo = @IdRigaPreventivo
              AND tipo.RigaLibera = 0
        )
        BEGIN
            THROW 51934, 'La riga non esiste oppure e una riga libera.', 1;
        END;

        IF @IdRigaCompPrev IS NOT NULL
           AND NOT EXISTS
           (
               SELECT 1
               FROM dbo.PreventiviRigheComponenti
               WHERE IdRigaCompPrev = @IdRigaCompPrev
                 AND IdRigaPreventivo = @IdRigaPreventivo
           )
        BEGIN
            THROW 51212, 'Il componente non appartiene alla riga indicata.', 1;
        END;

        INSERT INTO dbo.PreventiviRigheMateriali
        (
            IdRigaPreventivo,
            IdRigaCompPrev,
            IdNodoDistinta,
            IdMateriale,
            DescrizioneMateriale,
            TipoMateriale,
            UM,
            Quantita,
            CostoUnitario,
            CostoTotale,
            DaAcquistare,
            IdFornitoreSuggerito
        )
        VALUES
        (
            @IdRigaPreventivo,
            @IdRigaCompPrev,
            @IdNodoDistinta,
            @IdMateriale,
            @DescrizioneMateriale,
            @TipoMateriale,
            @UM,
            @Quantita,
            @CostoUnitario,
            ROUND(@Quantita * @CostoUnitario, 2),
            @DaAcquistare,
            @IdFornitoreSuggerito
        );

        SET @IdRigaMatPrev = CONVERT(INT, SCOPE_IDENTITY());

        EXEC dbo.sp_RicalcolaTotaliRigaPreventivo
            @IdRigaPreventivo = @IdRigaPreventivo;

        COMMIT TRANSACTION;

        SELECT @IdRigaMatPrev;
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

CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_Materiali_Elimina
    @IdRigaMatPrev INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @IdRigaPreventivo INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @IdRigaPreventivo = IdRigaPreventivo
        FROM dbo.PreventiviRigheMateriali
        WHERE IdRigaMatPrev = @IdRigaMatPrev;

        IF @IdRigaPreventivo IS NULL
        BEGIN
            THROW 51935, 'Materiale preventivo non trovato.', 1;
        END;

        DELETE FROM dbo.PreventiviRigheMateriali
        WHERE IdRigaMatPrev = @IdRigaMatPrev;

        EXEC dbo.sp_RicalcolaTotaliRigaPreventivo
            @IdRigaPreventivo = @IdRigaPreventivo;

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

CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_Lavorazioni_Crea
    @IdRigaPreventivo INT,
    @IdRigaCompPrev INT = NULL,
    @IdNodoDistinta INT = NULL,
    @IdLavorazione INT = NULL,
    @DescrizioneLavorazione NVARCHAR(300),
    @Sequenza INT = NULL,
    @TempoSetupMin DECIMAL(18,2),
    @TempoPezzoMin DECIMAL(18,4),
    @Quantita DECIMAL(18,4),
    @CostoOrario DECIMAL(18,4),
    @CostoFisso DECIMAL(18,4),
    @DaAcquistareEsterno BIT,
    @IdFornitoreSuggerito INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @TempoTotaleMin DECIMAL(18,4),
        @IdRigaLavPrev INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.PreventiviRighe AS riga
            INNER JOIN dbo.TipiRigaPreventivo AS tipo
                ON tipo.IdTipoRiga = riga.IdTipoRiga
            WHERE riga.IdRigaPreventivo = @IdRigaPreventivo
              AND tipo.RigaLibera = 0
        )
        BEGIN
            THROW 51936, 'La riga non esiste oppure e una riga libera.', 1;
        END;

        IF @IdRigaCompPrev IS NOT NULL
           AND NOT EXISTS
           (
               SELECT 1
               FROM dbo.PreventiviRigheComponenti
               WHERE IdRigaCompPrev = @IdRigaCompPrev
                 AND IdRigaPreventivo = @IdRigaPreventivo
           )
        BEGIN
            THROW 51222, 'Il componente non appartiene alla riga indicata.', 1;
        END;

        SET @TempoTotaleMin = @TempoSetupMin + @TempoPezzoMin * @Quantita;

        INSERT INTO dbo.PreventiviRigheLavorazioni
        (
            IdRigaPreventivo,
            IdRigaCompPrev,
            IdNodoDistinta,
            IdLavorazione,
            DescrizioneLavorazione,
            Sequenza,
            TempoSetupMin,
            TempoPezzoMin,
            Quantita,
            TempoTotaleMin,
            CostoOrario,
            CostoFisso,
            CostoTotale,
            DaAcquistareEsterno,
            IdFornitoreSuggerito
        )
        VALUES
        (
            @IdRigaPreventivo,
            @IdRigaCompPrev,
            @IdNodoDistinta,
            @IdLavorazione,
            @DescrizioneLavorazione,
            ISNULL(@Sequenza, 10),
            @TempoSetupMin,
            @TempoPezzoMin,
            @Quantita,
            @TempoTotaleMin,
            @CostoOrario,
            @CostoFisso,
            ROUND((@TempoTotaleMin / 60) * @CostoOrario + @CostoFisso, 2),
            @DaAcquistareEsterno,
            @IdFornitoreSuggerito
        );

        SET @IdRigaLavPrev = CONVERT(INT, SCOPE_IDENTITY());

        EXEC dbo.sp_RicalcolaTotaliRigaPreventivo
            @IdRigaPreventivo = @IdRigaPreventivo;

        COMMIT TRANSACTION;

        SELECT @IdRigaLavPrev;
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

CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_Lavorazioni_Elimina
    @IdRigaLavPrev INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @IdRigaPreventivo INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @IdRigaPreventivo = IdRigaPreventivo
        FROM dbo.PreventiviRigheLavorazioni
        WHERE IdRigaLavPrev = @IdRigaLavPrev;

        IF @IdRigaPreventivo IS NULL
        BEGIN
            THROW 51937, 'Lavorazione preventivo non trovata.', 1;
        END;

        DELETE FROM dbo.PreventiviRigheLavorazioni
        WHERE IdRigaLavPrev = @IdRigaLavPrev;

        EXEC dbo.sp_RicalcolaTotaliRigaPreventivo
            @IdRigaPreventivo = @IdRigaPreventivo;

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
