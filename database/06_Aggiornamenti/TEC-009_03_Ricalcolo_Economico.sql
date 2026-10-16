/*
    TEC-009 - Ricalcolo economico e selezione variante

    Prerequisiti:
    - TEC-009_01_Diagnostica_PreRicalcolo.sql conclusa senza blocchi;
    - TEC-009_02_Riconcilia_Riga_Libera_4.sql applicata;
    - esecuzione in finestra di manutenzione, dopo backup verificato;
    - database di destinazione selezionato esplicitamente dal client.

    Decisioni applicate: 164-172.
    Lo script non ricalcola i dati esistenti e non seleziona il database.
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET QUOTED_IDENTIFIER ON;
SET NUMERIC_ROUNDABORT OFF;

IF OBJECT_ID(N'dbo.Preventivi', N'U') IS NULL
   OR OBJECT_ID(N'dbo.PreventiviRighe', N'U') IS NULL
   OR OBJECT_ID(N'dbo.PreventiviRigheComponenti', N'U') IS NULL
   OR OBJECT_ID(N'dbo.PreventiviRigheMateriali', N'U') IS NULL
   OR OBJECT_ID(N'dbo.PreventiviRigheLavorazioni', N'U') IS NULL
   OR OBJECT_ID(N'dbo.PreventiviVarianti', N'U') IS NULL
   OR OBJECT_ID(N'dbo.TipiRigaPreventivo', N'U') IS NULL
BEGIN
    THROW 51921, 'TEC-009: schema richiesto non disponibile.', 1;
END;

IF EXISTS
(
    SELECT variante.IdPreventivo
    FROM dbo.PreventiviVarianti AS variante
    WHERE variante.Attiva = 1
      AND variante.VarianteScelta = 1
    GROUP BY variante.IdPreventivo
    HAVING COUNT(*) > 1
)
BEGIN
    THROW 51922, 'TEC-009: esistono preventivi con piu varianti attive selezionate.', 1;
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
    THROW 51923, 'TEC-009: esistono righe libere non conformi alla decisione 172.', 1;
END;

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'dbo.PreventiviVarianti')
      AND name = N'UX_PreventiviVarianti_UnaSceltaAttiva'
)
BEGIN
    CREATE UNIQUE INDEX UX_PreventiviVarianti_UnaSceltaAttiva
        ON dbo.PreventiviVarianti (IdPreventivo)
        WHERE Attiva = 1 AND VarianteScelta = 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_RicalcolaTotaliVariante
    @IdVariantePreventivo INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.PreventiviVarianti
        WHERE IdVariantePreventivo = @IdVariantePreventivo
    )
    BEGIN
        THROW 51924, 'Variante preventivo non trovata.', 1;
    END;

    DECLARE
        @TotaleCosti DECIMAL(18,2),
        @TotaleVendita DECIMAL(18,2),
        @MargineValore DECIMAL(18,2),
        @MarginePerc DECIMAL(9,2);

    SELECT
        @TotaleCosti = ISNULL(SUM(riga.TotaleCosti), 0),
        @TotaleVendita = ISNULL(SUM(riga.TotaleVendita), 0)
    FROM dbo.PreventiviRighe AS riga
    WHERE riga.IdVariantePreventivo = @IdVariantePreventivo;

    SET @MargineValore = @TotaleVendita - @TotaleCosti;
    SET @MarginePerc =
        CASE
            WHEN @TotaleVendita = 0 THEN 0
            ELSE ROUND((@MargineValore / @TotaleVendita) * 100, 2)
        END;

    UPDATE dbo.PreventiviVarianti
    SET TotaleCosti = @TotaleCosti,
        TotaleVendita = @TotaleVendita,
        MargineValore = @MargineValore,
        MarginePerc = @MarginePerc,
        DataModifica = SYSDATETIME()
    WHERE IdVariantePreventivo = @IdVariantePreventivo;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_RicalcolaTotaliPreventivo
    @IdPreventivo INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.Preventivi
        WHERE IdPreventivo = @IdPreventivo
    )
    BEGIN
        THROW 51925, 'Preventivo non trovato.', 1;
    END;

    IF
    (
        SELECT COUNT(*)
        FROM dbo.PreventiviVarianti
        WHERE IdPreventivo = @IdPreventivo
          AND Attiva = 1
          AND VarianteScelta = 1
    ) > 1
    BEGIN
        THROW 51926, 'Il preventivo ha piu varianti attive selezionate.', 1;
    END;

    DECLARE
        @IdVarianteSelezionata INT,
        @TotaleCosti DECIMAL(18,2),
        @TotaleVendita DECIMAL(18,2),
        @MargineValore DECIMAL(18,2),
        @MarginePerc DECIMAL(9,2);

    SELECT @IdVarianteSelezionata = variante.IdVariantePreventivo
    FROM dbo.PreventiviVarianti AS variante
    WHERE variante.IdPreventivo = @IdPreventivo
      AND variante.Attiva = 1
      AND variante.VarianteScelta = 1;

    SELECT
        @TotaleCosti = ISNULL(SUM(riga.TotaleCosti), 0),
        @TotaleVendita = ISNULL(SUM(riga.TotaleVendita), 0)
    FROM dbo.PreventiviRighe AS riga
    WHERE riga.IdPreventivo = @IdPreventivo
      AND
      (
          riga.IdVariantePreventivo IS NULL
          OR riga.IdVariantePreventivo = @IdVarianteSelezionata
      );

    SET @MargineValore = @TotaleVendita - @TotaleCosti;
    SET @MarginePerc =
        CASE
            WHEN @TotaleVendita = 0 THEN 0
            ELSE ROUND((@MargineValore / @TotaleVendita) * 100, 2)
        END;

    UPDATE dbo.Preventivi
    SET TotaleCosti = @TotaleCosti,
        TotaleVendita = @TotaleVendita,
        MargineValore = @MargineValore,
        MarginePerc = @MarginePerc,
        DataModifica = SYSDATETIME()
    WHERE IdPreventivo = @IdPreventivo;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_RicalcolaTotaliRigaPreventivo
    @IdRigaPreventivo INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @TotaleMateriali DECIMAL(18,2) = 0,
        @TotaleLavorazioni DECIMAL(18,2) = 0,
        @TotaleCosti DECIMAL(18,2) = 0,
        @Quantita DECIMAL(18,4),
        @MarkupPerc DECIMAL(9,2),
        @PrezzoManuale BIT,
        @PrezzoUnitarioVendita DECIMAL(18,4),
        @TotaleVendita DECIMAL(18,2),
        @MargineValore DECIMAL(18,2),
        @MarginePerc DECIMAL(9,2),
        @IdPreventivo INT,
        @IdVariantePreventivo INT,
        @RigaLibera BIT,
        @CostoUnitarioLibero DECIMAL(18,4);

    SELECT
        @Quantita = riga.Quantita,
        @MarkupPerc = riga.MarkupPerc,
        @PrezzoManuale = riga.PrezzoManuale,
        @PrezzoUnitarioVendita = riga.PrezzoUnitarioVendita,
        @IdPreventivo = riga.IdPreventivo,
        @IdVariantePreventivo = riga.IdVariantePreventivo,
        @RigaLibera = tipo.RigaLibera,
        @CostoUnitarioLibero = riga.CostoUnitarioLibero
    FROM dbo.PreventiviRighe AS riga
    INNER JOIN dbo.TipiRigaPreventivo AS tipo
        ON tipo.IdTipoRiga = riga.IdTipoRiga
    WHERE riga.IdRigaPreventivo = @IdRigaPreventivo;

    IF @IdPreventivo IS NULL
    BEGIN
        THROW 51927, 'Riga preventivo non trovata o priva di tipo riga valido.', 1;
    END;

    IF @RigaLibera = 1
       AND
       (
           @CostoUnitarioLibero IS NULL
           OR EXISTS
           (
               SELECT 1
               FROM dbo.PreventiviRigheComponenti
               WHERE IdRigaPreventivo = @IdRigaPreventivo
           )
           OR EXISTS
           (
               SELECT 1
               FROM dbo.PreventiviRigheMateriali
               WHERE IdRigaPreventivo = @IdRigaPreventivo
           )
           OR EXISTS
           (
               SELECT 1
               FROM dbo.PreventiviRigheLavorazioni
               WHERE IdRigaPreventivo = @IdRigaPreventivo
           )
       )
    BEGIN
        THROW 51928, 'La riga libera richiede un costo unitario e non puo contenere componenti, materiali o lavorazioni.', 1;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @RigaLibera = 0
        BEGIN
            UPDATE dbo.PreventiviRigheMateriali
            SET CostoTotale = ROUND(ISNULL(Quantita, 0) * ISNULL(CostoUnitario, 0), 2)
            WHERE IdRigaPreventivo = @IdRigaPreventivo;

            UPDATE dbo.PreventiviRigheLavorazioni
            SET TempoTotaleMin =
                    ISNULL(TempoSetupMin, 0)
                    + ISNULL(TempoPezzoMin, 0) * ISNULL(Quantita, 0),
                CostoTotale = ROUND
                (
                    (
                        ISNULL(TempoSetupMin, 0)
                        + ISNULL(TempoPezzoMin, 0) * ISNULL(Quantita, 0)
                    ) / 60.0 * ISNULL(CostoOrario, 0)
                    + ISNULL(CostoFisso, 0),
                    2
                )
            WHERE IdRigaPreventivo = @IdRigaPreventivo;

            SELECT @TotaleMateriali = ISNULL(SUM(CostoTotale), 0)
            FROM dbo.PreventiviRigheMateriali
            WHERE IdRigaPreventivo = @IdRigaPreventivo;

            SELECT @TotaleLavorazioni = ISNULL(SUM(CostoTotale), 0)
            FROM dbo.PreventiviRigheLavorazioni
            WHERE IdRigaPreventivo = @IdRigaPreventivo;

            SET @TotaleCosti = @TotaleMateriali + @TotaleLavorazioni;

            UPDATE dbo.PreventiviRighe
            SET CostoUnitarioLibero = NULL
            WHERE IdRigaPreventivo = @IdRigaPreventivo
              AND CostoUnitarioLibero IS NOT NULL;
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

        UPDATE dbo.PreventiviRighe
        SET TotaleCosti = @TotaleCosti,
            PrezzoUnitarioVendita = @PrezzoUnitarioVendita,
            TotaleVendita = @TotaleVendita,
            MargineValore = @MargineValore,
            MarginePerc = @MarginePerc,
            DataModifica = SYSDATETIME()
        WHERE IdRigaPreventivo = @IdRigaPreventivo;

        IF @IdVariantePreventivo IS NOT NULL
        BEGIN
            EXEC dbo.sp_RicalcolaTotaliVariante
                @IdVariantePreventivo = @IdVariantePreventivo;
        END;

        EXEC dbo.sp_RicalcolaTotaliPreventivo
            @IdPreventivo = @IdPreventivo;

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
