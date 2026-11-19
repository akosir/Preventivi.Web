-- Decisione 335: stato della revisione in anteprima.
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @Versione INT = 2026111602;
    DECLARE @Codice NVARCHAR(50) = N'TEC-016-STATO-SNAPSHOT';
    DECLARE @Script NVARCHAR(260) = N'TEC-016_12_Stato_Snapshot.sql';
    DECLARE @Impronta CHAR(64) = 'CDEFDDCAE630A775FAD8F2A6B9C6E87AD659A9A871BF85E3BB23FAFE3A4510F0';

    IF NOT EXISTS (SELECT 1 FROM dbo.VersioniSchema WITH (UPDLOCK, HOLDLOCK)
                   WHERE Versione = 2026111601 AND CodiceIntervento = N'TEC-016-APPLICA-SNAPSHOT')
        THROW 53896, 'Versione prerequisito 2026111601 non installata.', 1;
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

/* PAYLOAD TEC-016-STATO-SNAPSHOT START */
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

    IF EXISTS
    (
        SELECT 1 FROM dbo.PreventiviRigheComponenti
        WHERE IdRigaPreventivo = @IdRigaPreventivo
          AND IdRevisioneDistintaSnapshot = @Destinazione
    )
    BEGIN
        SELECT @Destinazione AS IdRevisione, @Numero AS NumeroRevisione,
               N''RevisioneGiaApplicata'' AS Tipo, N'''' AS Componente, N'''' AS Elemento;
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
/* PAYLOAD TEC-016-STATO-SNAPSHOT END */

    INSERT dbo.VersioniSchema (Versione, CodiceIntervento, NomeScript, Descrizione, ImprontaSha256)
    VALUES (@Versione, @Codice, @Script, N'Stato della revisione pubblicata nel controllo della riga.', @Impronta);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
