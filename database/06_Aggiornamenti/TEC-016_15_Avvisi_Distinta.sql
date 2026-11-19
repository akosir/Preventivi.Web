-- Decisione 337: righe articolo con distinta da verificare.
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @Versione INT = 2026111801;
    DECLARE @Codice NVARCHAR(50) = N'TEC-016-AVVISI-DISTINTA';
    DECLARE @Script NVARCHAR(260) = N'TEC-016_15_Avvisi_Distinta.sql';
    DECLARE @Impronta CHAR(64) = 'AAAFEEBD37FC24EF6CF9AC7E7D367F086978ED599C99BCD1D33CF573EA05C911';

    IF NOT EXISTS (SELECT 1 FROM dbo.VersioniSchema WITH (UPDLOCK, HOLDLOCK)
                   WHERE Versione = 2026111702 AND CodiceIntervento = N'TEC-016-DISTINTA-CORRENTE')
        THROW 53906, 'Versione prerequisito 2026111702 non installata.', 1;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione > @Versione)
        THROW 53907, 'Il database contiene una versione successiva.', 1;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione = @Versione
               AND CodiceIntervento = @Codice AND NomeScript = @Script AND ImprontaSha256 = @Impronta)
    BEGIN
        COMMIT TRANSACTION;
        RETURN;
    END;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione = @Versione
               OR CodiceIntervento = @Codice OR NomeScript = @Script)
        THROW 53908, 'Versione gia registrata con metadati differenti.', 1;

/* PAYLOAD TEC-016-AVVISI-DISTINTA START */
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_DistintaDaVerificare
        @IdPreventivo INT
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT r.IdRigaPreventivo, r.RigaNr, r.DescrizioneVoce,
               v.CodiceVariante, a.CodiceArticolo,
               CONVERT(BIT, CASE WHEN r.VersioneDistintaApplicata IS NULL THEN 0 ELSE 1 END) AS VersioneNota
        FROM dbo.PreventiviRighe AS r
        JOIN dbo.Preventivi AS p ON p.IdPreventivo = r.IdPreventivo
        JOIN dbo.TipiRigaPreventivo AS t ON t.IdTipoRiga = r.IdTipoRiga
        JOIN dbo.Articoli AS a ON a.IdArticolo = r.IdArticolo
        JOIN dbo.DistinteBase AS d ON d.IdArticolo = a.IdArticolo
        JOIN dbo.DistinteBaseRevisioni AS corrente
          ON corrente.IdDistintaBase = d.IdDistintaBase AND corrente.Stato = N''Pubblicata''
        LEFT JOIN dbo.PreventiviVarianti AS v ON v.IdVariantePreventivo = r.IdVariantePreventivo
        WHERE r.IdPreventivo = @IdPreventivo
          AND p.Stato IN (N''Bozza'', N''Da Verificare'', N''Pronto da Inviare'')
          AND t.RigaArticolo = 1 AND t.RigaLibera = 0
          AND (r.VersioneDistintaApplicata IS NULL
               OR r.VersioneDistintaApplicata <> corrente.VersioneContenuto
               OR NOT EXISTS (SELECT 1 FROM dbo.PreventiviRigheComponenti AS c
                              WHERE c.IdRigaPreventivo = r.IdRigaPreventivo
                                AND c.IdRevisioneDistintaSnapshot = corrente.IdRevisioneDistinta))
          AND EXISTS (SELECT 1 FROM dbo.DistintaBaseNodi AS n
                      WHERE n.IdRevisioneDistinta = corrente.IdRevisioneDistinta
                        AND n.IdNodoPadre IS NULL AND n.Attivo = 1)
        ORDER BY v.CodiceVariante, r.RigaNr, r.IdRigaPreventivo;
    END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_SnapshotIniziale
    @IdRigaPreventivo INT,
    @RevisioneConfermata INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @@TRANCOUNT = 0 THROW 53801, ''Snapshot richiesto fuori transazione.'', 1;

    DECLARE @IdArticolo INT, @IdRevisione INT, @VersioneContenuto BIGINT, @Quantita DECIMAL(18,4);
    SELECT @IdArticolo = r.IdArticolo, @Quantita = r.Quantita
    FROM dbo.PreventiviRighe AS r WITH (UPDLOCK, HOLDLOCK)
    JOIN dbo.TipiRigaPreventivo AS t ON t.IdTipoRiga = r.IdTipoRiga
    WHERE r.IdRigaPreventivo = @IdRigaPreventivo AND t.RigaArticolo = 1 AND t.RigaLibera = 0;
    IF @IdArticolo IS NULL RETURN;

    IF @RevisioneConfermata IS NULL AND
       (EXISTS (SELECT 1 FROM dbo.PreventiviRigheComponenti WITH (UPDLOCK, HOLDLOCK) WHERE IdRigaPreventivo = @IdRigaPreventivo)
       OR EXISTS (SELECT 1 FROM dbo.PreventiviRigheMateriali WITH (UPDLOCK, HOLDLOCK) WHERE IdRigaPreventivo = @IdRigaPreventivo)
       OR EXISTS (SELECT 1 FROM dbo.PreventiviRigheLavorazioni WITH (UPDLOCK, HOLDLOCK) WHERE IdRigaPreventivo = @IdRigaPreventivo))
        RETURN;

    SELECT @IdRevisione = rev.IdRevisioneDistinta, @VersioneContenuto = rev.VersioneContenuto
    FROM dbo.DistinteBase AS d
    JOIN dbo.DistinteBaseRevisioni AS rev WITH (HOLDLOCK) ON rev.IdDistintaBase = d.IdDistintaBase
    WHERE d.IdArticolo = @IdArticolo AND rev.Stato = N''Pubblicata'';
    IF @RevisioneConfermata IS NOT NULL AND (@IdRevisione IS NULL OR @IdRevisione <> @RevisioneConfermata)
        THROW 53803, ''La revisione pubblicata e cambiata.'', 1;
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

    UPDATE dbo.PreventiviRighe
    SET VersioneDistintaApplicata = @VersioneContenuto
    WHERE IdRigaPreventivo = @IdRigaPreventivo;

    IF @RevisioneConfermata IS NULL
        EXEC dbo.sp_RicalcolaTotaliRigaPreventivo @IdRigaPreventivo = @IdRigaPreventivo;
END;';
/* PAYLOAD TEC-016-AVVISI-DISTINTA END */

    INSERT dbo.VersioniSchema (Versione, CodiceIntervento, NomeScript, Descrizione, ImprontaSha256)
    VALUES (@Versione, @Codice, @Script, N'Avvisi sulle distinte da verificare in modifica preventivo.', @Impronta);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
