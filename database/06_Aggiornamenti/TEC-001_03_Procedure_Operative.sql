/*
    TEC-001 - Procedure operative

    Prerequisito:
    - TEC-001_02_Migrazione_Strutturale.sql completato con successo.

    Lo script non seleziona il database: eseguirlo esplicitamente
    sull'ambiente gia verificato.
*/

SET NOCOUNT ON;

IF COL_LENGTH(N'dbo.PreventiviRigheComponenti', N'IdRigaCompPrevPadre') IS NULL
   OR COL_LENGTH(N'dbo.PreventiviRigheComponenti', N'TipoOrigineComponente') IS NULL
   OR COL_LENGTH(N'dbo.PreventiviRigheComponenti', N'IdArticoloOrigine') IS NULL
   OR COL_LENGTH(N'dbo.PreventiviRigheMateriali', N'IdRigaCompPrev') IS NULL
   OR COL_LENGTH(N'dbo.PreventiviRigheLavorazioni', N'IdRigaCompPrev') IS NULL
BEGIN
    THROW 51301, 'TEC-001: eseguire prima la migrazione strutturale 02.', 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_Componenti_Elenco
    @IdRigaPreventivo INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        IdRigaCompPrev,
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
    FROM dbo.PreventiviRigheComponenti
    WHERE IdRigaPreventivo = @IdRigaPreventivo
    ORDER BY OrdineVisualizzazione, IdRigaCompPrev;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_Componenti_Dettaglio
    @IdRigaCompPrev INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        IdRigaCompPrev,
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
    FROM dbo.PreventiviRigheComponenti
    WHERE IdRigaCompPrev = @IdRigaCompPrev;
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

    DECLARE @QuantitaRiga DECIMAL(18,4);
    DECLARE @QuantitaPadre DECIMAL(18,4);
    DECLARE @QuantitaCalcolata DECIMAL(18,4);

    SELECT @QuantitaRiga = Quantita
    FROM dbo.PreventiviRighe
    WHERE IdRigaPreventivo = @IdRigaPreventivo;

    IF @QuantitaRiga IS NULL
    BEGIN
        THROW 51201, 'Riga preventivo non trovata.', 1;
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

    SELECT CONVERT(INT, SCOPE_IDENTITY());
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_Componenti_Elimina
    @IdRigaCompPrev INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM dbo.PreventiviRigheLavorazioni
        WHERE IdRigaCompPrev = @IdRigaCompPrev;

        DELETE FROM dbo.PreventiviRigheMateriali
        WHERE IdRigaCompPrev = @IdRigaCompPrev;

        DELETE FROM dbo.PreventiviRigheComponenti
        WHERE IdRigaCompPrev = @IdRigaCompPrev;

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

CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_Materiali_Elenco
    @IdRigaPreventivo INT,
    @IdRigaCompPrev INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        IdRigaMatPrev,
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
    FROM dbo.PreventiviRigheMateriali
    WHERE IdRigaPreventivo = @IdRigaPreventivo
      AND (
            IdRigaCompPrev = @IdRigaCompPrev
            OR (IdRigaCompPrev IS NULL AND @IdRigaCompPrev IS NULL)
          )
    ORDER BY DescrizioneMateriale, IdRigaMatPrev;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_Materiali_Dettaglio
    @IdRigaMatPrev INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        IdRigaMatPrev,
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
    FROM dbo.PreventiviRigheMateriali
    WHERE IdRigaMatPrev = @IdRigaMatPrev;
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

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.PreventiviRighe
        WHERE IdRigaPreventivo = @IdRigaPreventivo
    )
    BEGIN
        THROW 51211, 'Riga preventivo non trovata.', 1;
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

    SELECT CONVERT(INT, SCOPE_IDENTITY());
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_Lavorazioni_Elenco
    @IdRigaPreventivo INT,
    @IdRigaCompPrev INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        IdRigaLavPrev,
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
    FROM dbo.PreventiviRigheLavorazioni
    WHERE IdRigaPreventivo = @IdRigaPreventivo
      AND (
            IdRigaCompPrev = @IdRigaCompPrev
            OR (IdRigaCompPrev IS NULL AND @IdRigaCompPrev IS NULL)
          )
    ORDER BY Sequenza, IdRigaLavPrev;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_Lavorazioni_Dettaglio
    @IdRigaLavPrev INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        IdRigaLavPrev,
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
    FROM dbo.PreventiviRigheLavorazioni
    WHERE IdRigaLavPrev = @IdRigaLavPrev;
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

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.PreventiviRighe
        WHERE IdRigaPreventivo = @IdRigaPreventivo
    )
    BEGIN
        THROW 51221, 'Riga preventivo non trovata.', 1;
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

    DECLARE @TempoTotaleMin DECIMAL(18,4) =
        @TempoSetupMin + (@TempoPezzoMin * @Quantita);

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

    SELECT CONVERT(INT, SCOPE_IDENTITY());
END;
GO
