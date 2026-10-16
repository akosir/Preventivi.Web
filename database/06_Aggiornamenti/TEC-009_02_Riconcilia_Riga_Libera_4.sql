/*
    TEC-009 - Riconciliazione una tantum della riga libera 4

    Decisione 172:
    - una riga libera non contiene componenti, materiali o lavorazioni;
    - per la riga 4 si conservano costo totale 20,00 e vendita 50,00;
    - i componenti 10 e 11 e i relativi elementi, creati come dati di prova,
      vengono eliminati soltanto se corrispondono esattamente ai dati verificati.

    Prerequisiti:
    - TEC-001 gia applicata;
    - nessun allegato associato agli elementi eliminati;
    - esecuzione sul database PreventiviProduzione autorizzata separatamente.

    Lo script e idempotente rispetto allo stato finale previsto.
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @IdRigaPreventivo INT = 4;

IF OBJECT_ID(N'dbo.PreventiviRighe', N'U') IS NULL
   OR OBJECT_ID(N'dbo.PreventiviRigheComponenti', N'U') IS NULL
   OR OBJECT_ID(N'dbo.PreventiviRigheMateriali', N'U') IS NULL
   OR OBJECT_ID(N'dbo.PreventiviRigheLavorazioni', N'U') IS NULL
   OR OBJECT_ID(N'dbo.TipiRigaPreventivo', N'U') IS NULL
   OR OBJECT_ID(N'dbo.Allegati', N'U') IS NULL
BEGIN
    THROW 51911, 'TEC-009: schema richiesto non disponibile.', 1;
END;

IF EXISTS
(
    SELECT 1
    FROM dbo.PreventiviRighe AS riga
    INNER JOIN dbo.TipiRigaPreventivo AS tipo
        ON tipo.IdTipoRiga = riga.IdTipoRiga
    WHERE riga.IdRigaPreventivo = @IdRigaPreventivo
      AND tipo.RigaLibera = 1
      AND riga.CostoUnitarioLibero = CONVERT(DECIMAL(18,4), 20)
      AND riga.PrezzoManuale = 1
      AND riga.PrezzoUnitarioVendita = CONVERT(DECIMAL(18,4), 50)
      AND riga.TotaleCosti = CONVERT(DECIMAL(18,2), 20)
      AND riga.TotaleVendita = CONVERT(DECIMAL(18,2), 50)
)
AND NOT EXISTS
(
    SELECT 1
    FROM dbo.PreventiviRigheComponenti
    WHERE IdRigaPreventivo = @IdRigaPreventivo
)
AND NOT EXISTS
(
    SELECT 1
    FROM dbo.PreventiviRigheMateriali
    WHERE IdRigaPreventivo = @IdRigaPreventivo
)
AND NOT EXISTS
(
    SELECT 1
    FROM dbo.PreventiviRigheLavorazioni
    WHERE IdRigaPreventivo = @IdRigaPreventivo
)
BEGIN
    SELECT N'OK - riconciliazione TEC-009 gia applicata.' AS Esito;
    RETURN;
END;

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.PreventiviRighe AS riga
    INNER JOIN dbo.TipiRigaPreventivo AS tipo
        ON tipo.IdTipoRiga = riga.IdTipoRiga
    WHERE riga.IdRigaPreventivo = @IdRigaPreventivo
      AND riga.IdPreventivo = 1
      AND riga.RigaNr = 3
      AND tipo.Codice = N'LAV'
      AND tipo.RigaLibera = 1
      AND riga.Quantita = CONVERT(DECIMAL(18,4), 1)
      AND riga.CostoUnitarioLibero IS NULL
      AND riga.PrezzoManuale = 0
      AND riga.PrezzoUnitarioVendita = CONVERT(DECIMAL(18,4), 50)
      AND riga.TotaleCosti = CONVERT(DECIMAL(18,2), 20)
      AND riga.TotaleVendita = CONVERT(DECIMAL(18,2), 50)
)
BEGIN
    THROW 51912, 'TEC-009: la riga libera 4 non coincide con lo stato verificato.', 1;
END;

IF (SELECT COUNT(*) FROM dbo.PreventiviRigheComponenti WHERE IdRigaPreventivo = @IdRigaPreventivo) <> 2
   OR NOT EXISTS
   (
       SELECT 1
       FROM dbo.PreventiviRigheComponenti
       WHERE IdRigaCompPrev = 10
         AND IdRigaPreventivo = @IdRigaPreventivo
         AND IdRigaCompPrevPadre IS NULL
         AND DescrizioneNodo = N'Prova componente'
   )
   OR NOT EXISTS
   (
       SELECT 1
       FROM dbo.PreventiviRigheComponenti
       WHERE IdRigaCompPrev = 11
         AND IdRigaPreventivo = @IdRigaPreventivo
         AND IdRigaCompPrevPadre IS NULL
         AND DescrizioneNodo = N'Prova componente 2'
   )
BEGIN
    THROW 51913, 'TEC-009: i componenti della riga 4 non coincidono con i dati di prova verificati.', 1;
END;

IF (SELECT COUNT(*) FROM dbo.PreventiviRigheMateriali WHERE IdRigaPreventivo = @IdRigaPreventivo) <> 1
   OR NOT EXISTS
   (
       SELECT 1
       FROM dbo.PreventiviRigheMateriali
       WHERE IdRigaMatPrev = 10
         AND IdRigaPreventivo = @IdRigaPreventivo
         AND IdRigaCompPrev = 10
         AND DescrizioneMateriale = N'Carta'
   )
BEGIN
    THROW 51914, 'TEC-009: i materiali della riga 4 non coincidono con i dati di prova verificati.', 1;
END;

IF (SELECT COUNT(*) FROM dbo.PreventiviRigheLavorazioni WHERE IdRigaPreventivo = @IdRigaPreventivo) <> 2
   OR NOT EXISTS
   (
       SELECT 1
       FROM dbo.PreventiviRigheLavorazioni
       WHERE IdRigaLavPrev = 10
         AND IdRigaPreventivo = @IdRigaPreventivo
         AND IdRigaCompPrev = 10
         AND DescrizioneLavorazione = N'Stampa'
   )
   OR NOT EXISTS
   (
       SELECT 1
       FROM dbo.PreventiviRigheLavorazioni
       WHERE IdRigaLavPrev = 11
         AND IdRigaPreventivo = @IdRigaPreventivo
         AND IdRigaCompPrev = 11
         AND DescrizioneLavorazione = N'Sfridaturta completa'
   )
BEGIN
    THROW 51915, 'TEC-009: le lavorazioni della riga 4 non coincidono con i dati di prova verificati.', 1;
END;

IF EXISTS
(
    SELECT 1
    FROM dbo.Allegati
    WHERE (Entita = N'PreventiviRigheComponenti' AND IdEntita IN (10, 11))
       OR (Entita = N'PreventiviRigheMateriali' AND IdEntita = 10)
       OR (Entita = N'PreventiviRigheLavorazioni' AND IdEntita IN (10, 11))
)
BEGIN
    THROW 51916, 'TEC-009: pulizia interrotta perche esistono allegati associati ai dati di prova.', 1;
END;

BEGIN TRY
    BEGIN TRANSACTION;

    DELETE FROM dbo.PreventiviRigheLavorazioni
    WHERE IdRigaPreventivo = @IdRigaPreventivo;

    DELETE FROM dbo.PreventiviRigheMateriali
    WHERE IdRigaPreventivo = @IdRigaPreventivo;

    DELETE FROM dbo.PreventiviRigheComponenti
    WHERE IdRigaPreventivo = @IdRigaPreventivo;

    UPDATE dbo.PreventiviRighe
    SET CostoUnitarioLibero = CONVERT(DECIMAL(18,4), 20),
        PrezzoManuale = 1,
        PrezzoUnitarioVendita = CONVERT(DECIMAL(18,4), 50),
        TotaleCosti = CONVERT(DECIMAL(18,2), 20),
        TotaleVendita = CONVERT(DECIMAL(18,2), 50),
        MargineValore = CONVERT(DECIMAL(18,2), 30),
        MarginePerc = CONVERT(DECIMAL(9,2), 60),
        DataModifica = SYSDATETIME()
    WHERE IdRigaPreventivo = @IdRigaPreventivo;

    IF @@ROWCOUNT <> 1
    BEGIN
        THROW 51917, 'TEC-009: aggiornamento della riga libera 4 non riuscito.', 1;
    END;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;

    THROW;
END CATCH;

SELECT
    riga.IdRigaPreventivo,
    riga.CostoUnitarioLibero,
    riga.PrezzoManuale,
    riga.PrezzoUnitarioVendita,
    riga.TotaleCosti,
    riga.TotaleVendita,
    riga.MargineValore,
    riga.MarginePerc
FROM dbo.PreventiviRighe AS riga
WHERE riga.IdRigaPreventivo = @IdRigaPreventivo;

SELECT N'OK - riconciliazione TEC-009 applicata.' AS Esito;
