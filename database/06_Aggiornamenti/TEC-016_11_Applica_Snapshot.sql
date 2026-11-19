-- Decisione 335: applicazione transazionale della revisione confermata.
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @Versione INT = 2026111601;
    DECLARE @Codice NVARCHAR(50) = N'TEC-016-APPLICA-SNAPSHOT';
    DECLARE @Script NVARCHAR(260) = N'TEC-016_11_Applica_Snapshot.sql';
    DECLARE @Impronta CHAR(64) = 'DEAC8FC209753A230BB435CC09A8903CDD19772D50CA96D1F3DCF8DDA415869A';

    IF NOT EXISTS (SELECT 1 FROM dbo.VersioniSchema WITH (UPDLOCK, HOLDLOCK)
                   WHERE Versione = 2026111303 AND CodiceIntervento = N'TEC-016-ANTEPRIMA-SNAPSHOT')
        THROW 53896, 'Versione prerequisito 2026111303 non installata.', 1;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione > @Versione)
        THROW 53897, 'Il database contiene una versione successiva.', 1;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione = @Versione
               AND CodiceIntervento = @Codice AND NomeScript = @Script AND ImprontaSha256 = @Impronta)
    BEGIN
        COMMIT TRANSACTION;
        RETURN;
    END;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione = @Versione
               OR CodiceIntervento = @Codice OR NomeScript = @Script)
        THROW 53898, 'Versione gia registrata con metadati differenti.', 1;

/* PAYLOAD TEC-016-APPLICA-SNAPSHOT START */
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_SnapshotAnteprima
    @IdPreventivo INT,
    @IdRigaPreventivo INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Destinazione INT, @Numero INT;
    SELECT @Destinazione = rev.IdRevisioneDistinta, @Numero = rev.NumeroRevisione
    FROM dbo.PreventiviRighe AS r
    JOIN dbo.TipiRigaPreventivo AS t ON t.IdTipoRiga = r.IdTipoRiga AND t.RigaArticolo = 1 AND t.RigaLibera = 0
    JOIN dbo.DistinteBase AS d ON d.IdArticolo = r.IdArticolo
    JOIN dbo.DistinteBaseRevisioni AS rev ON rev.IdDistintaBase = d.IdDistintaBase AND rev.Stato = N''Pubblicata''
    WHERE r.IdPreventivo = @IdPreventivo AND r.IdRigaPreventivo = @IdRigaPreventivo;
    IF @Destinazione IS NULL RETURN;

    ;WITH ComponentiRimossi AS
    (
        SELECT c.IdRigaCompPrev, c.DescrizioneNodo
        FROM dbo.PreventiviRigheComponenti AS c
        JOIN dbo.DistintaBaseNodi AS origine ON origine.IdNodoDistinta = c.IdNodoDistinta
            AND origine.IdRevisioneDistinta = c.IdRevisioneDistintaSnapshot
        WHERE c.IdRigaPreventivo = @IdRigaPreventivo
          AND NOT EXISTS
          (
              SELECT 1 FROM dbo.DistintaBaseNodi AS nuovo
              WHERE nuovo.IdRevisioneDistinta = @Destinazione
                AND nuovo.ChiaveContinuita = origine.ChiaveContinuita AND nuovo.Attivo = 1
          )
    )
    SELECT @Destinazione AS IdRevisione, @Numero AS NumeroRevisione, N''Componente figlio'' AS Tipo,
           r.DescrizioneNodo AS Componente, c.DescrizioneNodo AS Elemento
    FROM ComponentiRimossi AS r
    JOIN dbo.PreventiviRigheComponenti AS c ON c.IdRigaCompPrevPadre = r.IdRigaCompPrev
    WHERE c.IdRigaPreventivo = @IdRigaPreventivo AND c.IdRevisioneDistintaSnapshot IS NULL
    UNION ALL
    SELECT @Destinazione, @Numero, N''Materiale'', r.DescrizioneNodo, m.DescrizioneMateriale
    FROM ComponentiRimossi AS r
    JOIN dbo.PreventiviRigheMateriali AS m ON m.IdRigaCompPrev = r.IdRigaCompPrev
    WHERE m.IdRigaPreventivo = @IdRigaPreventivo AND m.IdRevisioneDistintaSnapshot IS NULL
    UNION ALL
    SELECT @Destinazione, @Numero, N''Lavorazione'', r.DescrizioneNodo, l.DescrizioneLavorazione
    FROM ComponentiRimossi AS r
    JOIN dbo.PreventiviRigheLavorazioni AS l ON l.IdRigaCompPrev = r.IdRigaCompPrev
    WHERE l.IdRigaPreventivo = @IdRigaPreventivo AND l.IdRevisioneDistintaSnapshot IS NULL
    UNION ALL
    SELECT @Destinazione, @Numero, N'''', N'''', N''''
    ORDER BY Componente, Tipo, Elemento;
END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_SnapshotIniziale
    @IdRigaPreventivo INT,
    @RevisioneConfermata INT = NULL
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

    IF @RevisioneConfermata IS NULL AND
       (EXISTS (SELECT 1 FROM dbo.PreventiviRigheComponenti WITH (UPDLOCK, HOLDLOCK) WHERE IdRigaPreventivo = @IdRigaPreventivo)
       OR EXISTS (SELECT 1 FROM dbo.PreventiviRigheMateriali WITH (UPDLOCK, HOLDLOCK) WHERE IdRigaPreventivo = @IdRigaPreventivo)
       OR EXISTS (SELECT 1 FROM dbo.PreventiviRigheLavorazioni WITH (UPDLOCK, HOLDLOCK) WHERE IdRigaPreventivo = @IdRigaPreventivo))
        RETURN;

    SELECT @IdRevisione = rev.IdRevisioneDistinta
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

    IF @RevisioneConfermata IS NULL
        EXEC dbo.sp_RicalcolaTotaliRigaPreventivo @IdRigaPreventivo = @IdRigaPreventivo;
END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_SnapshotApplica
    @IdPreventivo INT,
    @IdRigaPreventivo INT,
    @IdRevisione INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.PreventiviRighe AS r WITH (UPDLOCK, HOLDLOCK)
            JOIN dbo.Preventivi AS p WITH (UPDLOCK, HOLDLOCK) ON p.IdPreventivo = r.IdPreventivo
            WHERE r.IdPreventivo = @IdPreventivo AND r.IdRigaPreventivo = @IdRigaPreventivo
              AND p.Stato = N''Bozza''
        )
            THROW 53804, ''L aggiornamento richiede un preventivo in bozza.'', 1;

        IF EXISTS (SELECT 1 FROM dbo.OrdiniFornitoriRighe WITH (UPDLOCK, HOLDLOCK)
                   WHERE IdRigaPreventivo = @IdRigaPreventivo)
            THROW 53805, ''La riga e collegata a un ordine fornitore.'', 1;

        DECLARE @Vecchi TABLE (Id INT PRIMARY KEY, Chiave UNIQUEIDENTIFIER NOT NULL);
        INSERT @Vecchi
        SELECT c.IdRigaCompPrev, n.ChiaveContinuita
        FROM dbo.PreventiviRigheComponenti AS c WITH (UPDLOCK, HOLDLOCK)
        JOIN dbo.DistintaBaseNodi AS n ON n.IdNodoDistinta = c.IdNodoDistinta
                                     AND n.IdRevisioneDistinta = c.IdRevisioneDistintaSnapshot
        WHERE c.IdRigaPreventivo = @IdRigaPreventivo;

        DECLARE @RigheBloccate INT;
        SELECT @RigheBloccate = COUNT(*) FROM dbo.PreventiviRigheComponenti WITH (UPDLOCK, HOLDLOCK)
        WHERE IdRigaPreventivo = @IdRigaPreventivo;
        SELECT @RigheBloccate = COUNT(*) FROM dbo.PreventiviRigheMateriali WITH (UPDLOCK, HOLDLOCK)
        WHERE IdRigaPreventivo = @IdRigaPreventivo;
        SELECT @RigheBloccate = COUNT(*) FROM dbo.PreventiviRigheLavorazioni WITH (UPDLOCK, HOLDLOCK)
        WHERE IdRigaPreventivo = @IdRigaPreventivo;

        IF EXISTS (SELECT 1 FROM dbo.PreventiviRigheComponenti
                   WHERE IdRigaPreventivo = @IdRigaPreventivo AND IdRevisioneDistintaSnapshot = @IdRevisione)
            THROW 53806, ''La revisione e gia applicata.'', 1;

        DECLARE @Esito TABLE (IdRevisione INT, NumeroRevisione INT, Tipo NVARCHAR(50),
                              Componente NVARCHAR(MAX), Elemento NVARCHAR(MAX));
        INSERT @Esito EXEC dbo.Preventivi_Righe_SnapshotAnteprima @IdPreventivo, @IdRigaPreventivo;
        IF @IdRevisione IS NULL OR NOT EXISTS (SELECT 1 FROM @Esito WHERE IdRevisione = @IdRevisione)
            THROW 53803, ''La revisione pubblicata e cambiata.'', 1;
        IF EXISTS (SELECT 1 FROM @Esito WHERE Tipo <> N'''')
            THROW 53807, ''Ricollocare gli elementi manuali indicati in anteprima.'', 1;

        IF EXISTS
        (
            SELECT 1 FROM dbo.Allegati AS a WITH (UPDLOCK, HOLDLOCK)
            WHERE (a.Entita = N''PreventiviRigheComponenti'' AND a.IdEntita IN (SELECT Id FROM @Vecchi))
               OR (a.Entita = N''PreventiviRigheMateriali'' AND a.IdEntita IN
                   (SELECT IdRigaMatPrev FROM dbo.PreventiviRigheMateriali
                    WHERE IdRigaPreventivo = @IdRigaPreventivo AND IdRevisioneDistintaSnapshot IS NOT NULL))
               OR (a.Entita = N''PreventiviRigheLavorazioni'' AND a.IdEntita IN
                   (SELECT IdRigaLavPrev FROM dbo.PreventiviRigheLavorazioni
                    WHERE IdRigaPreventivo = @IdRigaPreventivo AND IdRevisioneDistintaSnapshot IS NOT NULL))
        )
            THROW 53808, ''Lo snapshot contiene elementi con allegati.'', 1;

        DELETE dbo.PreventiviRigheMateriali
        WHERE IdRigaPreventivo = @IdRigaPreventivo AND IdRevisioneDistintaSnapshot IS NOT NULL;
        DELETE dbo.PreventiviRigheLavorazioni
        WHERE IdRigaPreventivo = @IdRigaPreventivo AND IdRevisioneDistintaSnapshot IS NOT NULL;

        EXEC dbo.Preventivi_Righe_SnapshotIniziale @IdRigaPreventivo, @IdRevisione;

        DECLARE @Mappa TABLE (Vecchio INT PRIMARY KEY, Nuovo INT NOT NULL);
        INSERT @Mappa
        SELECT v.Id, c.IdRigaCompPrev
        FROM @Vecchi AS v
        JOIN dbo.DistintaBaseNodi AS n ON n.ChiaveContinuita = v.Chiave AND n.IdRevisioneDistinta = @IdRevisione
        JOIN dbo.PreventiviRigheComponenti AS c ON c.IdNodoDistinta = n.IdNodoDistinta
           AND c.IdRigaPreventivo = @IdRigaPreventivo AND c.IdRevisioneDistintaSnapshot = @IdRevisione;

        UPDATE c SET IdRigaCompPrevPadre = m.Nuovo
        FROM dbo.PreventiviRigheComponenti AS c JOIN @Mappa AS m ON m.Vecchio = c.IdRigaCompPrevPadre
        WHERE c.IdRigaPreventivo = @IdRigaPreventivo AND c.IdRevisioneDistintaSnapshot IS NULL;
        UPDATE a SET IdRigaCompPrev = m.Nuovo
        FROM dbo.PreventiviRigheMateriali AS a JOIN @Mappa AS m ON m.Vecchio = a.IdRigaCompPrev
        WHERE a.IdRigaPreventivo = @IdRigaPreventivo AND a.IdRevisioneDistintaSnapshot IS NULL;
        UPDATE a SET IdRigaCompPrev = m.Nuovo
        FROM dbo.PreventiviRigheLavorazioni AS a JOIN @Mappa AS m ON m.Vecchio = a.IdRigaCompPrev
        WHERE a.IdRigaPreventivo = @IdRigaPreventivo AND a.IdRevisioneDistintaSnapshot IS NULL;

        DELETE c FROM dbo.PreventiviRigheComponenti AS c JOIN @Vecchi AS v ON v.Id = c.IdRigaCompPrev;

        EXEC dbo.sp_RicalcolaQuantitaComponentiRiga @IdRigaPreventivo = @IdRigaPreventivo;
        EXEC dbo.sp_RicalcolaTotaliRigaPreventivo @IdRigaPreventivo = @IdRigaPreventivo;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;';
/* PAYLOAD TEC-016-APPLICA-SNAPSHOT END */

    INSERT dbo.VersioniSchema (Versione, CodiceIntervento, NomeScript, Descrizione, ImprontaSha256)
    VALUES (@Versione, @Codice, @Script, N'Applicazione confermata della revisione pubblicata.', @Impronta);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
