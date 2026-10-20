SET XACT_ABORT ON;
GO

CREATE OR ALTER PROCEDURE dbo.ModelliCiclo_Lookup
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        IdModelloCiclo,
        CodiceModelloCiclo,
        Descrizione
    FROM dbo.ModelliCiclo
    WHERE Attivo = 1
    ORDER BY CodiceModelloCiclo, Descrizione;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Fornitori_Lookup
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        IdFornitore,
        CodiceFornitore,
        RagioneSociale
    FROM dbo.Fornitori
    WHERE Attivo = 1
    ORDER BY RagioneSociale, CodiceFornitore;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Aggiorna
    @IdPreventivo INT,
    @DataPreventivo DATE,
    @IdCliente INT = NULL,
    @Oggetto NVARCHAR(250),
    @Note NVARCHAR(MAX) = NULL,
    @Stato NVARCHAR(30),
    @MarkupPercDefault DECIMAL(9,2),
    @IdRichiestaCliente INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NULLIF(LTRIM(RTRIM(@Oggetto)), N'') IS NULL
        THROW 52001, 'L''oggetto del preventivo e obbligatorio.', 1;

    IF @MarkupPercDefault < 0
        THROW 52002, 'Il markup predefinito non puo essere negativo.', 1;

    UPDATE dbo.Preventivi
    SET DataPreventivo = @DataPreventivo,
        IdCliente = @IdCliente,
        Oggetto = LTRIM(RTRIM(@Oggetto)),
        Note = NULLIF(LTRIM(RTRIM(@Note)), N''),
        Stato = @Stato,
        MarkupPercDefault = @MarkupPercDefault,
        IdRichiestaCliente = @IdRichiestaCliente,
        DataModifica = SYSDATETIME()
    WHERE IdPreventivo = @IdPreventivo;

    IF @@ROWCOUNT = 0
        THROW 52003, 'Preventivo non trovato.', 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_RicalcolaQuantitaComponentiRiga
    @IdRigaPreventivo INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @QuantitaRiga DECIMAL(18,4);

    SELECT @QuantitaRiga = Quantita
    FROM dbo.PreventiviRighe
    WHERE IdRigaPreventivo = @IdRigaPreventivo;

    IF @QuantitaRiga IS NULL
        THROW 52014, 'Riga preventivo non trovata durante il ricalcolo delle quantita.', 1;

    ;WITH QuantitaGerarchiche AS
    (
        SELECT
            componente.IdRigaCompPrev,
            CONVERT(DECIMAL(38,8), @QuantitaRiga * componente.QuantitaBase) AS QuantitaAttesa,
            0 AS Profondita
        FROM dbo.PreventiviRigheComponenti AS componente
        WHERE componente.IdRigaPreventivo = @IdRigaPreventivo
          AND componente.IdRigaCompPrevPadre IS NULL

        UNION ALL

        SELECT
            figlio.IdRigaCompPrev,
            CONVERT(DECIMAL(38,8), padre.QuantitaAttesa * figlio.QuantitaBase),
            padre.Profondita + 1
        FROM QuantitaGerarchiche AS padre
        INNER JOIN dbo.PreventiviRigheComponenti AS figlio
            ON figlio.IdRigaCompPrevPadre = padre.IdRigaCompPrev
           AND figlio.IdRigaPreventivo = @IdRigaPreventivo
        WHERE padre.Profondita < 100
    )
    UPDATE componente
    SET QuantitaCalcolata = CONVERT(DECIMAL(18,4), quantita.QuantitaAttesa)
    FROM dbo.PreventiviRigheComponenti AS componente
    INNER JOIN QuantitaGerarchiche AS quantita
        ON quantita.IdRigaCompPrev = componente.IdRigaCompPrev
    OPTION (MAXRECURSION 100);
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_Aggiorna
    @IdRigaPreventivo INT,
    @RigaNr INT,
    @DescrizioneVoce NVARCHAR(250),
    @Quantita DECIMAL(18,4),
    @PrezzoUnitarioVendita DECIMAL(18,4),
    @Note NVARCHAR(MAX) = NULL,
    @MarkupPerc DECIMAL(9,2),
    @PrezzoManuale BIT,
    @CostoUnitarioLibero DECIMAL(18,4) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RigaLibera BIT;

    SELECT @RigaLibera = tipo.RigaLibera
    FROM dbo.PreventiviRighe AS riga
    INNER JOIN dbo.TipiRigaPreventivo AS tipo
        ON tipo.IdTipoRiga = riga.IdTipoRiga
    WHERE riga.IdRigaPreventivo = @IdRigaPreventivo;

    IF @RigaLibera IS NULL
        THROW 52004, 'Riga preventivo non trovata.', 1;

    IF @RigaNr <= 0 OR @Quantita <= 0
        THROW 52005, 'Numero riga e quantita devono essere maggiori di zero.', 1;

    IF NULLIF(LTRIM(RTRIM(@DescrizioneVoce)), N'') IS NULL
        THROW 52006, 'La descrizione della riga e obbligatoria.', 1;

    IF @RigaLibera = 1 AND @CostoUnitarioLibero IS NULL
        THROW 52007, 'La riga libera richiede il costo unitario libero.', 1;

    IF @RigaLibera = 0
        SET @CostoUnitarioLibero = NULL;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.PreventiviRighe
        SET RigaNr = @RigaNr,
            DescrizioneVoce = LTRIM(RTRIM(@DescrizioneVoce)),
            Quantita = @Quantita,
            PrezzoUnitarioVendita = @PrezzoUnitarioVendita,
            Note = NULLIF(LTRIM(RTRIM(@Note)), N''),
            MarkupPerc = @MarkupPerc,
            PrezzoManuale = @PrezzoManuale,
            CostoUnitarioLibero = @CostoUnitarioLibero,
            DataModifica = SYSDATETIME()
        WHERE IdRigaPreventivo = @IdRigaPreventivo;

        EXEC dbo.sp_RicalcolaQuantitaComponentiRiga
            @IdRigaPreventivo = @IdRigaPreventivo;

        EXEC dbo.sp_RicalcolaTotaliRigaPreventivo
            @IdRigaPreventivo = @IdRigaPreventivo;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_Componenti_Aggiorna
    @IdRigaCompPrev INT,
    @DescrizioneNodo NVARCHAR(200),
    @QuantitaBase DECIMAL(18,4),
    @OrdineVisualizzazione INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @IdRigaPreventivo INT;

    SELECT @IdRigaPreventivo = IdRigaPreventivo
    FROM dbo.PreventiviRigheComponenti
    WHERE IdRigaCompPrev = @IdRigaCompPrev;

    IF @IdRigaPreventivo IS NULL
        THROW 52008, 'Componente preventivo non trovato.', 1;

    IF NULLIF(LTRIM(RTRIM(@DescrizioneNodo)), N'') IS NULL OR @QuantitaBase <= 0
        THROW 52009, 'Descrizione e quantita base del componente non sono valide.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.PreventiviRigheComponenti
        SET DescrizioneNodo = LTRIM(RTRIM(@DescrizioneNodo)),
            QuantitaBase = @QuantitaBase,
            OrdineVisualizzazione = @OrdineVisualizzazione
        WHERE IdRigaCompPrev = @IdRigaCompPrev;

        EXEC dbo.sp_RicalcolaQuantitaComponentiRiga
            @IdRigaPreventivo = @IdRigaPreventivo;

        EXEC dbo.sp_RicalcolaTotaliRigaPreventivo
            @IdRigaPreventivo = @IdRigaPreventivo;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_Materiali_Aggiorna
    @IdRigaMatPrev INT,
    @DescrizioneMateriale NVARCHAR(200),
    @TipoMateriale NVARCHAR(30) = NULL,
    @UM NVARCHAR(10) = NULL,
    @Quantita DECIMAL(18,4),
    @CostoUnitario DECIMAL(18,4),
    @DaAcquistare BIT,
    @IdFornitoreSuggerito INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @IdRigaPreventivo INT;

    SELECT @IdRigaPreventivo = IdRigaPreventivo
    FROM dbo.PreventiviRigheMateriali
    WHERE IdRigaMatPrev = @IdRigaMatPrev;

    IF @IdRigaPreventivo IS NULL
        THROW 52010, 'Materiale preventivo non trovato.', 1;

    IF NULLIF(LTRIM(RTRIM(@DescrizioneMateriale)), N'') IS NULL OR @Quantita < 0 OR @CostoUnitario < 0
        THROW 52011, 'Descrizione, quantita o costo del materiale non sono validi.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.PreventiviRigheMateriali
        SET DescrizioneMateriale = LTRIM(RTRIM(@DescrizioneMateriale)),
            TipoMateriale = NULLIF(LTRIM(RTRIM(@TipoMateriale)), N''),
            UM = NULLIF(LTRIM(RTRIM(@UM)), N''),
            Quantita = @Quantita,
            CostoUnitario = @CostoUnitario,
            CostoTotale = ROUND(@Quantita * @CostoUnitario, 2),
            DaAcquistare = @DaAcquistare,
            IdFornitoreSuggerito = @IdFornitoreSuggerito
        WHERE IdRigaMatPrev = @IdRigaMatPrev;

        EXEC dbo.sp_RicalcolaTotaliRigaPreventivo
            @IdRigaPreventivo = @IdRigaPreventivo;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_Lavorazioni_Aggiorna
    @IdRigaLavPrev INT,
    @DescrizioneLavorazione NVARCHAR(150),
    @Sequenza INT,
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
        @IdRigaPreventivo INT,
        @TempoTotaleMin DECIMAL(18,4);

    SELECT @IdRigaPreventivo = IdRigaPreventivo
    FROM dbo.PreventiviRigheLavorazioni
    WHERE IdRigaLavPrev = @IdRigaLavPrev;

    IF @IdRigaPreventivo IS NULL
        THROW 52012, 'Lavorazione preventivo non trovata.', 1;

    IF NULLIF(LTRIM(RTRIM(@DescrizioneLavorazione)), N'') IS NULL
       OR @TempoSetupMin < 0 OR @TempoPezzoMin < 0 OR @Quantita < 0
       OR @CostoOrario < 0 OR @CostoFisso < 0
        THROW 52013, 'I dati economici della lavorazione non sono validi.', 1;

    SET @TempoTotaleMin = @TempoSetupMin + @TempoPezzoMin * @Quantita;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.PreventiviRigheLavorazioni
        SET DescrizioneLavorazione = LTRIM(RTRIM(@DescrizioneLavorazione)),
            Sequenza = @Sequenza,
            TempoSetupMin = @TempoSetupMin,
            TempoPezzoMin = @TempoPezzoMin,
            Quantita = @Quantita,
            TempoTotaleMin = @TempoTotaleMin,
            CostoOrario = @CostoOrario,
            CostoFisso = @CostoFisso,
            CostoTotale = ROUND((@TempoTotaleMin / 60) * @CostoOrario + @CostoFisso, 2),
            DaAcquistareEsterno = @DaAcquistareEsterno,
            IdFornitoreSuggerito = @IdFornitoreSuggerito
        WHERE IdRigaLavPrev = @IdRigaLavPrev;

        EXEC dbo.sp_RicalcolaTotaliRigaPreventivo
            @IdRigaPreventivo = @IdRigaPreventivo;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
