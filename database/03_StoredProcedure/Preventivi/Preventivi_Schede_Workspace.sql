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
    @IdNodoDistinta INT = NULL,
    @IdNodoPadre INT = NULL,
    @DescrizioneNodo NVARCHAR(400),
    @Livello INT,
    @QuantitaBase DECIMAL(18,4),
    @QuantitaCalcolata DECIMAL(18,4),
    @OrdineVisualizzazione INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.PreventiviRigheComponenti
    (
        IdRigaPreventivo,
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

    DELETE FROM dbo.PreventiviRigheComponenti
    WHERE IdRigaCompPrev = @IdRigaCompPrev;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_Materiali_Elenco
    @IdRigaPreventivo INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        IdRigaMatPrev,
        IdRigaPreventivo,
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

    INSERT INTO dbo.PreventiviRigheMateriali
    (
        IdRigaPreventivo,
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
    @IdRigaPreventivo INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        IdRigaLavPrev,
        IdRigaPreventivo,
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

    DECLARE @TempoTotaleMin DECIMAL(18,4) =
        @TempoSetupMin + (@TempoPezzoMin * @Quantita);

    INSERT INTO dbo.PreventiviRigheLavorazioni
    (
        IdRigaPreventivo,
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
