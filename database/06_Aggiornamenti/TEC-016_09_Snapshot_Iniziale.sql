-- Decisione 335: copia iniziale della distinta pubblicata.
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @Versione INT = 2026111302;
    DECLARE @Codice NVARCHAR(50) = N'TEC-016-SNAPSHOT-INIZIALE';
    DECLARE @Script NVARCHAR(260) = N'TEC-016_09_Snapshot_Iniziale.sql';
    DECLARE @Impronta CHAR(64) = 'B266AA58CD1565FDB2B89407683DBD76104325C9665E1028AD8F1C8D92CB5A42';

    IF NOT EXISTS (SELECT 1 FROM dbo.VersioniSchema WITH (UPDLOCK, HOLDLOCK)
                   WHERE Versione = 2026111301 AND CodiceIntervento = N'TEC-016-CONTINUITA-NODI')
        THROW 53893, 'Versione prerequisito 2026111301 non installata.', 1;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione > @Versione)
        THROW 53894, 'Il database contiene una versione successiva.', 1;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione = @Versione
               AND CodiceIntervento = @Codice AND NomeScript = @Script AND ImprontaSha256 = @Impronta)
    BEGIN
        COMMIT TRANSACTION;
        RETURN;
    END;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione = @Versione
               OR CodiceIntervento = @Codice OR NomeScript = @Script)
        THROW 53895, 'Versione gia registrata con metadati differenti.', 1;

/* PAYLOAD TEC-016-SNAPSHOT-INIZIALE START */
    ALTER TABLE dbo.PreventiviRigheComponenti ADD IdRevisioneDistintaSnapshot INT NULL;
    ALTER TABLE dbo.PreventiviRigheMateriali ADD IdDistintaMaterialeSnapshot INT NULL, IdRevisioneDistintaSnapshot INT NULL;
    ALTER TABLE dbo.PreventiviRigheLavorazioni ADD IdDistintaLavorazioneSnapshot INT NULL, IdRevisioneDistintaSnapshot INT NULL;

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_SnapshotIniziale
    @IdRigaPreventivo INT
AS
BEGIN
    SET NOCOUNT ON;
    IF @@TRANCOUNT = 0 THROW 53801, ''Snapshot richiesto fuori transazione.'', 1;

    DECLARE @IdArticolo INT, @IdRevisione INT, @Quantita DECIMAL(18,4);
    SELECT @IdArticolo = r.IdArticolo, @Quantita = r.Quantita
    FROM dbo.PreventiviRighe AS r WITH (UPDLOCK, HOLDLOCK)
    JOIN dbo.TipiRigaPreventivo AS t ON t.IdTipoRiga = r.IdTipoRiga
    WHERE r.IdRigaPreventivo = @IdRigaPreventivo AND t.RigaArticolo = 1 AND t.RigaLibera = 0;
    IF @IdArticolo IS NULL RETURN;

    IF EXISTS (SELECT 1 FROM dbo.PreventiviRigheComponenti WITH (UPDLOCK, HOLDLOCK) WHERE IdRigaPreventivo = @IdRigaPreventivo)
       OR EXISTS (SELECT 1 FROM dbo.PreventiviRigheMateriali WITH (UPDLOCK, HOLDLOCK) WHERE IdRigaPreventivo = @IdRigaPreventivo)
       OR EXISTS (SELECT 1 FROM dbo.PreventiviRigheLavorazioni WITH (UPDLOCK, HOLDLOCK) WHERE IdRigaPreventivo = @IdRigaPreventivo)
        RETURN;

    SELECT @IdRevisione = rev.IdRevisioneDistinta
    FROM dbo.DistinteBase AS d
    JOIN dbo.DistinteBaseRevisioni AS rev WITH (HOLDLOCK) ON rev.IdDistintaBase = d.IdDistintaBase
    WHERE d.IdArticolo = @IdArticolo AND rev.Stato = N''Pubblicata'';
    IF @IdRevisione IS NULL RETURN;

    DECLARE @Mappa TABLE (IdNodoDistinta INT PRIMARY KEY, IdComponente INT NOT NULL, Quantita DECIMAL(18,4) NOT NULL);
    DECLARE @Livello INT = 0;
    WHILE 1 = 1
    BEGIN
        MERGE dbo.PreventiviRigheComponenti AS destinazione
        USING
        (
            SELECT n.*, padre.IdComponente AS IdComponentePadre,
                   CONVERT(DECIMAL(18,4), n.QuantitaBase * COALESCE(padre.Quantita, @Quantita)) AS QuantitaOperativa
            FROM dbo.DistintaBaseNodi AS n
            LEFT JOIN @Mappa AS padre ON padre.IdNodoDistinta = n.IdNodoPadre
            WHERE n.IdRevisioneDistinta = @IdRevisione AND n.Attivo = 1 AND n.Livello = @Livello
              AND (n.IdNodoPadre IS NULL OR padre.IdComponente IS NOT NULL)
        ) AS origine ON 1 = 0
        WHEN NOT MATCHED THEN INSERT
            (IdRigaPreventivo, IdRigaCompPrevPadre, TipoOrigineComponente, IdArticoloOrigine,
             IdNodoDistinta, IdNodoPadre, DescrizioneNodo, Livello, QuantitaBase,
             QuantitaCalcolata, OrdineVisualizzazione, IdRevisioneDistintaSnapshot)
        VALUES
            (@IdRigaPreventivo, origine.IdComponentePadre, N''Distinta'', @IdArticolo,
             origine.IdNodoDistinta, origine.IdNodoPadre, origine.DescrizioneNodo, origine.Livello,
             origine.QuantitaBase, origine.QuantitaOperativa, origine.OrdineVisualizzazione, @IdRevisione)
        OUTPUT origine.IdNodoDistinta, inserted.IdRigaCompPrev, inserted.QuantitaCalcolata INTO @Mappa;
        IF @@ROWCOUNT = 0 BREAK;
        SET @Livello += 1;
    END;

    IF (SELECT COUNT(*) FROM @Mappa) <>
       (SELECT COUNT(*) FROM dbo.DistintaBaseNodi WHERE IdRevisioneDistinta = @IdRevisione AND Attivo = 1)
        THROW 53802, ''Gerarchia della revisione pubblicata incompleta.'', 1;

    INSERT dbo.PreventiviRigheMateriali
        (IdRigaPreventivo, IdRigaCompPrev, IdNodoDistinta, IdMateriale, DescrizioneMateriale,
         TipoMateriale, UM, Quantita, CostoUnitario, CostoTotale, DaAcquistare,
         IdDistintaMaterialeSnapshot, IdRevisioneDistintaSnapshot)
    SELECT @IdRigaPreventivo, c.IdComponente, c.IdNodoDistinta, m.IdMateriale, a.Descrizione,
           a.TipoMateriale, u.CodiceUM, ROUND(c.Quantita * m.Quantita * (1 + m.CoeffScartoPerc / 100.0), 4),
           m.CostoUnitario, 0, 0, m.IdDistintaMateriale, @IdRevisione
    FROM @Mappa AS c
    JOIN dbo.DistintaMateriali AS m ON m.IdNodoDistinta = c.IdNodoDistinta
    JOIN dbo.Materiali AS a ON a.IdMateriale = m.IdMateriale
    JOIN dbo.UnitaMisura AS u ON u.IdUM = a.IdUM;

    INSERT dbo.PreventiviRigheLavorazioni
        (IdRigaPreventivo, IdRigaCompPrev, IdNodoDistinta, IdLavorazione, DescrizioneLavorazione,
         Sequenza, TempoSetupMin, TempoPezzoMin, Quantita, TempoTotaleMin, CostoOrario,
         CostoFisso, CostoTotale, DaAcquistareEsterno, IdDistintaLavorazioneSnapshot, IdRevisioneDistintaSnapshot)
    SELECT @IdRigaPreventivo, c.IdComponente, c.IdNodoDistinta, l.IdLavorazione, a.Descrizione,
           l.Sequenza, l.TempoSetupMin, l.TempoPezzoMin, c.Quantita, 0, l.CostoOrario,
           l.CostoFisso, 0, 0, l.IdDistintaLavorazione, @IdRevisione
    FROM @Mappa AS c
    JOIN dbo.DistintaLavorazioni AS l ON l.IdNodoDistinta = c.IdNodoDistinta
    JOIN dbo.Lavorazioni AS a ON a.IdLavorazione = l.IdLavorazione;

    EXEC dbo.sp_RicalcolaTotaliRigaPreventivo @IdRigaPreventivo = @IdRigaPreventivo;
END;';
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_Crea
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
            THROW 51942, ''Preventivo non trovato.'', 1;
        END;

        SELECT @RigaLibera = RigaLibera
        FROM dbo.TipiRigaPreventivo
        WHERE IdTipoRiga = @IdTipoRiga
          AND Attiva = 1;

        IF @RigaLibera IS NULL
        BEGIN
            THROW 51943, ''Tipo riga non trovato o non attivo.'', 1;
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
            THROW 51944, ''La variante non appartiene al preventivo o non e attiva.'', 1;
        END;

        IF @Quantita <= 0
        BEGIN
            THROW 51945, ''La quantita deve essere maggiore di zero.'', 1;
        END;

        IF @RigaLibera = 1 AND @CostoUnitarioLibero IS NULL
        BEGIN
            THROW 51946, ''La riga libera richiede il costo unitario libero.'', 1;
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

        EXEC dbo.Preventivi_Righe_SnapshotIniziale @IdRigaPreventivo;

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
END;';
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_Aggiorna
    @IdRigaPreventivo INT,
    @RigaNr INT,
    @DescrizioneVoce NVARCHAR(250),
    @Quantita DECIMAL(18,4),
    @PrezzoUnitarioVendita DECIMAL(18,4),
    @Note NVARCHAR(MAX) = NULL,
    @MarkupPerc DECIMAL(9,2),
    @PrezzoManuale BIT,
    @CostoUnitarioLibero DECIMAL(18,4) = NULL,
    @IdTipoRiga INT,
    @IdArticolo INT = NULL,
    @IdModelloCiclo INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @RigaArticolo BIT,
        @RigaLibera BIT,
        @ObbligaArticolo BIT,
        @RichiedeCostoLibero BIT;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.PreventiviRighe
        WHERE IdRigaPreventivo = @IdRigaPreventivo
    )
        THROW 52004, ''Riga preventivo non trovata.'', 1;

    SELECT
        @RigaArticolo = RigaArticolo,
        @RigaLibera = RigaLibera,
        @ObbligaArticolo = ObbligaArticolo
    FROM dbo.TipiRigaPreventivo
    WHERE IdTipoRiga = @IdTipoRiga
      AND Attiva = 1;

    IF @RigaLibera IS NULL
        THROW 52015, ''Tipo riga non trovato o non attivo.'', 1;

    SET @RichiedeCostoLibero =
        CASE WHEN @RigaLibera = 1 AND @RigaArticolo = 0 THEN 1 ELSE 0 END;

    IF @RigaNr <= 0 OR @Quantita <= 0
        THROW 52005, ''Numero riga e quantita devono essere maggiori di zero.'', 1;

    IF NULLIF(LTRIM(RTRIM(@DescrizioneVoce)), N'''') IS NULL
        THROW 52006, ''La descrizione della riga e obbligatoria.'', 1;

    IF @RichiedeCostoLibero = 1 AND @CostoUnitarioLibero IS NULL
        THROW 52007, ''La riga libera richiede il costo unitario libero.'', 1;

    IF @RichiedeCostoLibero = 0
        SET @CostoUnitarioLibero = NULL;

    IF @RigaArticolo = 0
    BEGIN
        SET @IdArticolo = NULL;
        SET @IdModelloCiclo = NULL;
    END;
    ELSE
    BEGIN
        IF @ObbligaArticolo = 1 AND @IdArticolo IS NULL
            THROW 52016, ''Il tipo riga richiede un articolo.'', 1;

        IF @IdArticolo IS NOT NULL
           AND NOT EXISTS
           (
               SELECT 1
               FROM dbo.Articoli
               WHERE IdArticolo = @IdArticolo
                 AND Attivo = 1
           )
            THROW 52016, ''Articolo non trovato o non attivo.'', 1;

        IF @IdModelloCiclo IS NOT NULL
           AND NOT EXISTS
           (
               SELECT 1
               FROM dbo.ModelliCiclo
               WHERE IdModelloCiclo = @IdModelloCiclo
                 AND Attivo = 1
           )
            THROW 52017, ''Modello ciclo non trovato o non attivo.'', 1;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @ArticoloPrecedente INT, @EraRigaArticolo BIT;
        SELECT @ArticoloPrecedente = r.IdArticolo, @EraRigaArticolo = t.RigaArticolo
        FROM dbo.PreventiviRighe AS r WITH (UPDLOCK, HOLDLOCK)
        JOIN dbo.TipiRigaPreventivo AS t ON t.IdTipoRiga = r.IdTipoRiga
        WHERE r.IdRigaPreventivo = @IdRigaPreventivo;

        UPDATE dbo.PreventiviRighe
        SET IdTipoRiga = @IdTipoRiga,
            IdArticolo = @IdArticolo,
            IdModelloCiclo = @IdModelloCiclo,
            RigaNr = @RigaNr,
            DescrizioneVoce = LTRIM(RTRIM(@DescrizioneVoce)),
            Quantita = @Quantita,
            PrezzoUnitarioVendita = @PrezzoUnitarioVendita,
            Note = NULLIF(LTRIM(RTRIM(@Note)), N''''),
            MarkupPerc = @MarkupPerc,
            PrezzoManuale = @PrezzoManuale,
            CostoUnitarioLibero = @CostoUnitarioLibero,
            DataModifica = SYSDATETIME()
        WHERE IdRigaPreventivo = @IdRigaPreventivo;

        IF @RigaArticolo = 1 AND @IdArticolo IS NOT NULL
           AND (@EraRigaArticolo = 0 OR ISNULL(@ArticoloPrecedente, 0) <> @IdArticolo)
            EXEC dbo.Preventivi_Righe_SnapshotIniziale @IdRigaPreventivo;

        EXEC dbo.sp_RicalcolaQuantitaComponentiRiga
            @IdRigaPreventivo = @IdRigaPreventivo;

        EXEC dbo.sp_RicalcolaTotaliRigaPreventivo
            @IdRigaPreventivo = @IdRigaPreventivo;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;';
/* PAYLOAD TEC-016-SNAPSHOT-INIZIALE END */

    INSERT dbo.VersioniSchema (Versione, CodiceIntervento, NomeScript, Descrizione, ImprontaSha256)
    VALUES (@Versione, @Codice, @Script, N'Copia iniziale della distinta pubblicata nella riga articolo.', @Impronta);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
