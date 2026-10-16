/*
    TEC-009 - Riconciliazione finale dei totali esistenti

    Prerequisiti:
    - script TEC-009 da 01 a 06 completati con successo;
    - backup verificato e finestra di manutenzione attiva;
    - database di destinazione selezionato esplicitamente dal client.

    Impatto:
    - ricalcola i dettagli e i totali di ogni riga;
    - ricalcola tutte le varianti, anche non attive;
    - ricalcola ogni testata secondo la variante attiva selezionata;
    - non crea o elimina dati gestionali.

    Lo script e ripetibile e non seleziona il database.
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID(N'dbo.sp_RicalcolaTotaliRigaPreventivo', N'P') IS NULL
   OR OBJECT_ID(N'dbo.sp_RicalcolaTotaliVariante', N'P') IS NULL
   OR OBJECT_ID(N'dbo.sp_RicalcolaTotaliPreventivo', N'P') IS NULL
   OR OBJECT_ID(N'dbo.Preventivi_Varianti_Seleziona', N'P') IS NULL
BEGIN
    THROW 51961, 'TEC-009: applicare prima gli script dal 03 al 06.', 1;
END;

IF EXISTS
(
    SELECT 1
    FROM dbo.PreventiviRighe AS riga
    INNER JOIN dbo.TipiRigaPreventivo AS tipo
        ON tipo.IdTipoRiga = riga.IdTipoRiga
    WHERE tipo.RigaLibera = 1
      AND
      (
          riga.CostoUnitarioLibero IS NULL
          OR EXISTS
          (
              SELECT 1
              FROM dbo.PreventiviRigheComponenti AS componente
              WHERE componente.IdRigaPreventivo = riga.IdRigaPreventivo
          )
          OR EXISTS
          (
              SELECT 1
              FROM dbo.PreventiviRigheMateriali AS materiale
              WHERE materiale.IdRigaPreventivo = riga.IdRigaPreventivo
          )
          OR EXISTS
          (
              SELECT 1
              FROM dbo.PreventiviRigheLavorazioni AS lavorazione
              WHERE lavorazione.IdRigaPreventivo = riga.IdRigaPreventivo
          )
      )
)
BEGIN
    THROW 51962, 'TEC-009: esistono righe libere non riconciliate.', 1;
END;

DECLARE
    @IdRigaPreventivo INT,
    @IdVariantePreventivo INT,
    @IdPreventivo INT;

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE righe CURSOR LOCAL FAST_FORWARD FOR
        SELECT IdRigaPreventivo
        FROM dbo.PreventiviRighe
        ORDER BY IdRigaPreventivo;

    OPEN righe;

    FETCH NEXT FROM righe INTO @IdRigaPreventivo;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC dbo.sp_RicalcolaTotaliRigaPreventivo
            @IdRigaPreventivo = @IdRigaPreventivo;

        FETCH NEXT FROM righe INTO @IdRigaPreventivo;
    END;

    CLOSE righe;
    DEALLOCATE righe;

    DECLARE varianti CURSOR LOCAL FAST_FORWARD FOR
        SELECT IdVariantePreventivo
        FROM dbo.PreventiviVarianti
        ORDER BY IdVariantePreventivo;

    OPEN varianti;

    FETCH NEXT FROM varianti INTO @IdVariantePreventivo;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC dbo.sp_RicalcolaTotaliVariante
            @IdVariantePreventivo = @IdVariantePreventivo;

        FETCH NEXT FROM varianti INTO @IdVariantePreventivo;
    END;

    CLOSE varianti;
    DEALLOCATE varianti;

    DECLARE preventivi CURSOR LOCAL FAST_FORWARD FOR
        SELECT IdPreventivo
        FROM dbo.Preventivi
        ORDER BY IdPreventivo;

    OPEN preventivi;

    FETCH NEXT FROM preventivi INTO @IdPreventivo;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC dbo.sp_RicalcolaTotaliPreventivo
            @IdPreventivo = @IdPreventivo;

        FETCH NEXT FROM preventivi INTO @IdPreventivo;
    END;

    CLOSE preventivi;
    DEALLOCATE preventivi;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF CURSOR_STATUS('local', 'righe') > -1
    BEGIN
        CLOSE righe;
    END;

    IF CURSOR_STATUS('local', 'righe') > -3
    BEGIN
        DEALLOCATE righe;
    END;

    IF CURSOR_STATUS('local', 'varianti') > -1
    BEGIN
        CLOSE varianti;
    END;

    IF CURSOR_STATUS('local', 'varianti') > -3
    BEGIN
        DEALLOCATE varianti;
    END;

    IF CURSOR_STATUS('local', 'preventivi') > -1
    BEGIN
        CLOSE preventivi;
    END;

    IF CURSOR_STATUS('local', 'preventivi') > -3
    BEGIN
        DEALLOCATE preventivi;
    END;

    IF XACT_STATE() <> 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;

    THROW;
END CATCH;

SELECT
    preventivo.IdPreventivo,
    preventivo.TotaleCosti,
    preventivo.TotaleVendita,
    preventivo.MargineValore,
    preventivo.MarginePerc
FROM dbo.Preventivi AS preventivo
ORDER BY preventivo.IdPreventivo;

SELECT N'OK - riconciliazione totali TEC-009 completata.' AS Esito;
