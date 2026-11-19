-- Decisioni 337-339: aggiornamento della distinta corrente confermata.
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @Versione INT = 2026111802;
    DECLARE @Codice NVARCHAR(50) = N'TEC-016-AGGIORNA-DISTINTA';
    DECLARE @Script NVARCHAR(260) = N'TEC-016_16_Aggiorna_Distinta.sql';
    DECLARE @Impronta CHAR(64) = 'B983A52C7A6D5CB7E66C520DE974C0E018C2DE0A17F90E4359AA55BBEAF768AE';

    IF NOT EXISTS (SELECT 1 FROM dbo.VersioniSchema WITH (UPDLOCK, HOLDLOCK)
                   WHERE Versione = 2026111801 AND CodiceIntervento = N'TEC-016-AVVISI-DISTINTA')
        THROW 53896, 'Versione prerequisito 2026111801 non installata.', 1;
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

/* PAYLOAD TEC-016-AGGIORNA-DISTINTA START */
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_SnapshotAnteprima
    @IdPreventivo INT,
    @IdRigaPreventivo INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Destinazione INT, @Numero INT, @Versione BIGINT, @Applicata BIGINT;
    SELECT @Destinazione = rev.IdRevisioneDistinta, @Numero = rev.NumeroRevisione,
           @Versione = rev.VersioneContenuto, @Applicata = r.VersioneDistintaApplicata
    FROM dbo.PreventiviRighe AS r
    JOIN dbo.TipiRigaPreventivo AS t ON t.IdTipoRiga = r.IdTipoRiga AND t.RigaArticolo = 1 AND t.RigaLibera = 0
    JOIN dbo.DistinteBase AS d ON d.IdArticolo = r.IdArticolo
    JOIN dbo.DistinteBaseRevisioni AS rev ON rev.IdDistintaBase = d.IdDistintaBase AND rev.Stato = N''Pubblicata''
    WHERE r.IdPreventivo = @IdPreventivo AND r.IdRigaPreventivo = @IdRigaPreventivo;
    IF @Destinazione IS NULL RETURN;

    IF @Applicata = @Versione AND EXISTS
    (
        SELECT 1 FROM dbo.PreventiviRigheComponenti
        WHERE IdRigaPreventivo = @IdRigaPreventivo
          AND IdRevisioneDistintaSnapshot = @Destinazione
    )
    BEGIN
        SELECT @Destinazione AS IdRevisione, @Numero AS NumeroRevisione,
               N''RevisioneGiaApplicata'' AS Tipo, N'''' AS Componente, N'''' AS Elemento, @Versione AS VersioneContenuto;
        RETURN;
    END;

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
           r.DescrizioneNodo AS Componente, c.DescrizioneNodo AS Elemento, @Versione AS VersioneContenuto
    FROM ComponentiRimossi AS r
    JOIN dbo.PreventiviRigheComponenti AS c ON c.IdRigaCompPrevPadre = r.IdRigaCompPrev
    WHERE c.IdRigaPreventivo = @IdRigaPreventivo AND c.IdRevisioneDistintaSnapshot IS NULL
    UNION ALL
    SELECT @Destinazione, @Numero, N''Materiale'', r.DescrizioneNodo, m.DescrizioneMateriale, @Versione
    FROM ComponentiRimossi AS r
    JOIN dbo.PreventiviRigheMateriali AS m ON m.IdRigaCompPrev = r.IdRigaCompPrev
    WHERE m.IdRigaPreventivo = @IdRigaPreventivo AND m.IdRevisioneDistintaSnapshot IS NULL
    UNION ALL
    SELECT @Destinazione, @Numero, N''Lavorazione'', r.DescrizioneNodo, l.DescrizioneLavorazione, @Versione
    FROM ComponentiRimossi AS r
    JOIN dbo.PreventiviRigheLavorazioni AS l ON l.IdRigaCompPrev = r.IdRigaCompPrev
    WHERE l.IdRigaPreventivo = @IdRigaPreventivo AND l.IdRevisioneDistintaSnapshot IS NULL
    UNION ALL
    SELECT @Destinazione, @Numero, N'''', N'''', N'''', @Versione
    ORDER BY Componente, Tipo, Elemento;
END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_SnapshotApplica
    @IdPreventivo INT,
    @IdRigaPreventivo INT,
    @IdRevisione INT,
    @VersioneContenuto BIGINT
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
              AND p.Stato IN (N''Bozza'', N''Da Verificare'', N''Pronto da Inviare'')
        )
            THROW 53804, ''Lo stato del preventivo non consente l aggiornamento.'', 1;

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

        IF @VersioneContenuto IS NULL OR NOT EXISTS
        (
            SELECT 1 FROM dbo.DistinteBaseRevisioni AS rev WITH (UPDLOCK, HOLDLOCK)
            JOIN dbo.DistinteBase AS d ON d.IdDistintaBase = rev.IdDistintaBase
            JOIN dbo.PreventiviRighe AS r ON r.IdArticolo = d.IdArticolo
            WHERE r.IdRigaPreventivo = @IdRigaPreventivo AND rev.IdRevisioneDistinta = @IdRevisione
              AND rev.Stato = N''Pubblicata'' AND rev.VersioneContenuto = @VersioneContenuto
        )
            THROW 53803, ''Il contenuto della distinta e cambiato.'', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.DistintaBaseNodi
                       WHERE IdRevisioneDistinta = @IdRevisione AND IdNodoPadre IS NULL AND Attivo = 1)
            THROW 53802, ''La distinta corrente non contiene una radice attiva.'', 1;

        IF EXISTS (SELECT 1 FROM dbo.PreventiviRigheComponenti AS c
                   WHERE c.IdRigaPreventivo = @IdRigaPreventivo AND c.IdRevisioneDistintaSnapshot IS NOT NULL
                     AND NOT EXISTS (SELECT 1 FROM @Vecchi AS v WHERE v.Id = c.IdRigaCompPrev))
            THROW 53802, ''Provenienza di un componente non disponibile.'', 1;

        DECLARE @Esito TABLE (IdRevisione INT, NumeroRevisione INT, Tipo NVARCHAR(50),
                              Componente NVARCHAR(MAX), Elemento NVARCHAR(MAX), VersioneContenuto BIGINT);
        INSERT @Esito EXEC dbo.Preventivi_Righe_SnapshotAnteprima @IdPreventivo, @IdRigaPreventivo;
        IF @IdRevisione IS NULL OR NOT EXISTS (SELECT 1 FROM @Esito WHERE IdRevisione = @IdRevisione)
            THROW 53803, ''La revisione pubblicata e cambiata.'', 1;
        IF EXISTS (SELECT 1 FROM @Esito WHERE Tipo = N''RevisioneGiaApplicata'')
            THROW 53806, ''La distinta e gia aggiornata.'', 1;
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
           AND c.IdRigaPreventivo = @IdRigaPreventivo AND c.IdRevisioneDistintaSnapshot = @IdRevisione
        WHERE NOT EXISTS (SELECT 1 FROM @Vecchi AS precedente WHERE precedente.Id = c.IdRigaCompPrev);

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
/* PAYLOAD TEC-016-AGGIORNA-DISTINTA END */

    INSERT dbo.VersioniSchema (Versione, CodiceIntervento, NomeScript, Descrizione, ImprontaSha256)
    VALUES (@Versione, @Codice, @Script, N'Aggiornamento confermato della distinta corrente nel preventivo.', @Impronta);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
