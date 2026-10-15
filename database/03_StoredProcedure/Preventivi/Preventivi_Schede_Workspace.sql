USE PreventiviProduzione;
GO

CREATE OR ALTER PROCEDURE dbo.TipiRigaPreventivo_Elenco
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        IdTipoRiga,
        Codice,
        Descrizione
    FROM dbo.TipiRigaPreventivo
    WHERE Attiva = 1
    ORDER BY Ordinamento, Descrizione;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Articoli_Ricerca
    @Ricerca NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (50)
        IdArticolo,
        CodiceArticolo,
        Descrizione,
        Versione
    FROM dbo.Articoli
    WHERE Attivo = 1
      AND (
            @Ricerca IS NULL
            OR CodiceArticolo LIKE '%' + @Ricerca + '%'
            OR Descrizione LIKE '%' + @Ricerca + '%'
          )
    ORDER BY CodiceArticolo, Descrizione;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Articoli_Dettaglio_Lookup
    @IdArticolo INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        IdArticolo,
        CodiceArticolo,
        Descrizione,
        Versione
    FROM dbo.Articoli
    WHERE IdArticolo = @IdArticolo;
END;
GO

CREATE OR ALTER PROCEDURE dbo.DistintaBaseNodi_Elenco
    @IdArticolo INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        n.IdNodoDistinta,
        n.IdArticolo,
        n.IdNodoPadre,
        n.CodiceNodo,
        n.DescrizioneNodo,
        n.Livello,
        n.QuantitaBase,
        n.OrdineVisualizzazione,
        ISNULL(t.Descrizione, '') AS TipoNodo
    FROM dbo.DistintaBaseNodi AS n
    LEFT JOIN dbo.TipiNodoDistinta AS t
        ON t.IdTipoNodo = n.IdTipoNodo
    WHERE n.IdArticolo = @IdArticolo
      AND n.Attivo = 1
    ORDER BY n.OrdineVisualizzazione, n.IdNodoDistinta;
END;
GO

CREATE OR ALTER PROCEDURE dbo.DistintaBaseNodi_Dettaglio
    @IdNodoDistinta INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        n.IdNodoDistinta,
        n.IdArticolo,
        n.IdNodoPadre,
        n.CodiceNodo,
        n.DescrizioneNodo,
        n.Livello,
        n.QuantitaBase,
        n.OrdineVisualizzazione,
        ISNULL(t.Descrizione, '') AS TipoNodo
    FROM dbo.DistintaBaseNodi AS n
    LEFT JOIN dbo.TipiNodoDistinta AS t
        ON t.IdTipoNodo = n.IdTipoNodo
    WHERE n.IdNodoDistinta = @IdNodoDistinta;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Materiali_Ricerca
    @Ricerca NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (50)
        IdMateriale,
        CodiceMateriale,
        Descrizione,
        TipoMateriale,
        CONVERT(NVARCHAR(20), IdUM) AS UM,
        CostoUnitario,
        GestitoAAcquisto,
        IdFornitorePredefinito
    FROM dbo.Materiali
    WHERE Attivo = 1
      AND (
            @Ricerca IS NULL
            OR CodiceMateriale LIKE '%' + @Ricerca + '%'
            OR Descrizione LIKE '%' + @Ricerca + '%'
          )
    ORDER BY CodiceMateriale, Descrizione;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Materiali_Dettaglio_Lookup
    @IdMateriale INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        IdMateriale,
        CodiceMateriale,
        Descrizione,
        TipoMateriale,
        CONVERT(NVARCHAR(20), IdUM) AS UM,
        CostoUnitario,
        GestitoAAcquisto,
        IdFornitorePredefinito
    FROM dbo.Materiali
    WHERE IdMateriale = @IdMateriale;
END;
GO

CREATE OR ALTER PROCEDURE dbo.DistintaMateriali_Elenco
    @IdNodoDistinta INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        dm.IdDistintaMateriale,
        dm.IdNodoDistinta,
        dm.IdMateriale,
        ISNULL(m.CodiceMateriale, '') AS CodiceMateriale,
        ISNULL(m.Descrizione, '') AS DescrizioneMateriale,
        m.TipoMateriale,
        CONVERT(NVARCHAR(20), m.IdUM) AS UM,
        dm.Quantita,
        ISNULL(m.CostoUnitario, 0) AS CostoUnitario,
        ISNULL(m.GestitoAAcquisto, 0) AS DaAcquistare,
        m.IdFornitorePredefinito AS IdFornitoreSuggerito
    FROM dbo.DistintaMateriali AS dm
    INNER JOIN dbo.Materiali AS m
        ON m.IdMateriale = dm.IdMateriale
    WHERE dm.IdNodoDistinta = @IdNodoDistinta
    ORDER BY m.CodiceMateriale, m.Descrizione;
END;
GO

CREATE OR ALTER PROCEDURE dbo.DistintaMateriali_Dettaglio
    @IdDistintaMateriale INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        dm.IdDistintaMateriale,
        dm.IdNodoDistinta,
        dm.IdMateriale,
        ISNULL(m.CodiceMateriale, '') AS CodiceMateriale,
        ISNULL(m.Descrizione, '') AS DescrizioneMateriale,
        m.TipoMateriale,
        CONVERT(NVARCHAR(20), m.IdUM) AS UM,
        dm.Quantita,
        ISNULL(m.CostoUnitario, 0) AS CostoUnitario,
        ISNULL(m.GestitoAAcquisto, 0) AS DaAcquistare,
        m.IdFornitorePredefinito AS IdFornitoreSuggerito
    FROM dbo.DistintaMateriali AS dm
    INNER JOIN dbo.Materiali AS m
        ON m.IdMateriale = dm.IdMateriale
    WHERE dm.IdDistintaMateriale = @IdDistintaMateriale;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Lavorazioni_Ricerca
    @Ricerca NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (50)
        IdLavorazione,
        CodiceLavorazione,
        Descrizione,
        InternaEsterna,
        CostoOrarioStandard,
        TempoSetupMinDefault,
        TempoPezzoMinDefault,
        AcquistabileEsterna,
        IdFornitorePredefinito
    FROM dbo.Lavorazioni
    WHERE Attiva = 1
      AND (
            @Ricerca IS NULL
            OR CodiceLavorazione LIKE '%' + @Ricerca + '%'
            OR Descrizione LIKE '%' + @Ricerca + '%'
          )
    ORDER BY CodiceLavorazione, Descrizione;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Lavorazioni_Dettaglio_Lookup
    @IdLavorazione INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        IdLavorazione,
        CodiceLavorazione,
        Descrizione,
        InternaEsterna,
        CostoOrarioStandard,
        TempoSetupMinDefault,
        TempoPezzoMinDefault,
        AcquistabileEsterna,
        IdFornitorePredefinito
    FROM dbo.Lavorazioni
    WHERE IdLavorazione = @IdLavorazione;
END;
GO

CREATE OR ALTER PROCEDURE dbo.DistintaLavorazioni_Elenco
    @IdNodoDistinta INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        dl.IdDistintaLavorazione,
        dl.IdNodoDistinta,
        dl.IdLavorazione,
        ISNULL(l.CodiceLavorazione, '') AS CodiceLavorazione,
        ISNULL(l.Descrizione, '') AS DescrizioneLavorazione,
        dl.Sequenza,
        dl.TempoSetupMin,
        dl.TempoPezzoMin,
        dl.CostoOrario,
        dl.CostoFisso,
        ISNULL(l.AcquistabileEsterna, 0) AS DaAcquistareEsterno,
        l.IdFornitorePredefinito AS IdFornitoreSuggerito
    FROM dbo.DistintaLavorazioni AS dl
    INNER JOIN dbo.Lavorazioni AS l
        ON l.IdLavorazione = dl.IdLavorazione
    WHERE dl.IdNodoDistinta = @IdNodoDistinta
    ORDER BY dl.Sequenza, l.CodiceLavorazione;
END;
GO

CREATE OR ALTER PROCEDURE dbo.DistintaLavorazioni_Dettaglio
    @IdDistintaLavorazione INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        dl.IdDistintaLavorazione,
        dl.IdNodoDistinta,
        dl.IdLavorazione,
        ISNULL(l.CodiceLavorazione, '') AS CodiceLavorazione,
        ISNULL(l.Descrizione, '') AS DescrizioneLavorazione,
        dl.Sequenza,
        dl.TempoSetupMin,
        dl.TempoPezzoMin,
        dl.CostoOrario,
        dl.CostoFisso,
        ISNULL(l.AcquistabileEsterna, 0) AS DaAcquistareEsterno,
        l.IdFornitorePredefinito AS IdFornitoreSuggerito
    FROM dbo.DistintaLavorazioni AS dl
    INNER JOIN dbo.Lavorazioni AS l
        ON l.IdLavorazione = dl.IdLavorazione
    WHERE dl.IdDistintaLavorazione = @IdDistintaLavorazione;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_Dettaglio
    @IdRigaPreventivo INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        r.IdRigaPreventivo,
        r.IdPreventivo,
        r.RigaNr,
        r.IdArticolo,
        r.IdModelloCiclo,
        r.DescrizioneVoce,
        r.Quantita,
        r.PrezzoUnitarioVendita,
        r.TotaleVendita,
        r.TotaleCosti,
        r.MargineValore,
        r.MarginePerc,
        r.Note,
        r.MarkupPerc,
        r.PrezzoManuale,
        r.IdVariantePreventivo,
        r.CostoUnitarioLibero,
        r.IdTipoRiga,
        ISNULL(t.Descrizione, '') AS TipoRiga
    FROM dbo.PreventiviRighe AS r
    INNER JOIN dbo.TipiRigaPreventivo AS t
        ON t.IdTipoRiga = r.IdTipoRiga
    WHERE r.IdRigaPreventivo = @IdRigaPreventivo;
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
    @TotaleCosti DECIMAL(18,2),
    @Note NVARCHAR(MAX) = NULL,
    @MarkupPerc DECIMAL(9,2),
    @PrezzoManuale BIT,
    @IdVariantePreventivo INT = NULL,
    @CostoUnitarioLibero DECIMAL(18,4) = NULL,
    @IdTipoRiga INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NumeroRiga INT =
        ISNULL(
            @RigaNr,
            ISNULL(
                (
                    SELECT MAX(RigaNr)
                    FROM dbo.PreventiviRighe
                    WHERE IdPreventivo = @IdPreventivo
                ),
                0
            ) + 1
        );

    DECLARE @TotaleVendita DECIMAL(18,2) =
        ROUND(@Quantita * @PrezzoUnitarioVendita, 2);

    DECLARE @MargineValore DECIMAL(18,2) =
        @TotaleVendita - @TotaleCosti;

    DECLARE @MarginePerc DECIMAL(9,2) =
        CASE
            WHEN @TotaleVendita = 0 THEN 0
            ELSE ROUND((@MargineValore / @TotaleVendita) * 100, 2)
        END;

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

    SELECT CONVERT(INT, SCOPE_IDENTITY());
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_Elimina
    @IdRigaPreventivo INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM dbo.PreventiviRigheLavorazioni
    WHERE IdRigaPreventivo = @IdRigaPreventivo;

    DELETE FROM dbo.PreventiviRigheMateriali
    WHERE IdRigaPreventivo = @IdRigaPreventivo;

    DELETE FROM dbo.PreventiviRigheComponenti
    WHERE IdRigaPreventivo = @IdRigaPreventivo;

    DELETE FROM dbo.PreventiviRighe
    WHERE IdRigaPreventivo = @IdRigaPreventivo;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Varianti_Elenco
    @IdPreventivo INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        IdVariantePreventivo,
        IdPreventivo,
        CodiceVariante,
        DescrizioneVariante,
        VarianteScelta,
        TotaleCosti,
        TotaleVendita,
        MargineValore,
        MarginePerc
    FROM dbo.PreventiviVarianti
    WHERE IdPreventivo = @IdPreventivo
      AND Attiva = 1
    ORDER BY CodiceVariante, IdVariantePreventivo;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Varianti_Dettaglio
    @IdVariantePreventivo INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        IdVariantePreventivo,
        IdPreventivo,
        CodiceVariante,
        DescrizioneVariante,
        VarianteScelta,
        TotaleCosti,
        TotaleVendita,
        MargineValore,
        MarginePerc
    FROM dbo.PreventiviVarianti
    WHERE IdVariantePreventivo = @IdVariantePreventivo;
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

    SELECT CONVERT(INT, SCOPE_IDENTITY());
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Varianti_Elimina
    @IdVariantePreventivo INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.PreventiviVarianti
    SET
        Attiva = 0,
        DataModifica = SYSDATETIME()
    WHERE IdVariantePreventivo = @IdVariantePreventivo;
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

CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_Materiali_Elimina
    @IdRigaMatPrev INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM dbo.PreventiviRigheMateriali
    WHERE IdRigaMatPrev = @IdRigaMatPrev;
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

CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_Lavorazioni_Elimina
    @IdRigaLavPrev INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM dbo.PreventiviRigheLavorazioni
    WHERE IdRigaLavPrev = @IdRigaLavPrev;
END;
GO
