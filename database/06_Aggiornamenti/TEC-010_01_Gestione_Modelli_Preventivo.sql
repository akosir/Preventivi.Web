/*
    TEC-010 - Gestione modelli preventivo

    Prerequisiti:
    - baseline TEC-002;
    - TEC-008_03_Tipo_Riga_Modelli.sql;
    - TEC-008_04_Regole_Riga_Articolo_Modelli.sql.

    Lo script non contiene USE. Se rileva riferimenti orfani, espone le righe
    interessate e si interrompe senza modificarle.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
GO

IF OBJECT_ID(N'dbo.ModelliPreventivo', N'U') IS NULL
   OR OBJECT_ID(N'dbo.ModelliPreventivoRighe', N'U') IS NULL
   OR OBJECT_ID(N'dbo.Clienti', N'U') IS NULL
   OR OBJECT_ID(N'dbo.Articoli', N'U') IS NULL
   OR OBJECT_ID(N'dbo.ModelliCiclo', N'U') IS NULL
   OR OBJECT_ID(N'dbo.TipiRigaPreventivo', N'U') IS NULL
   OR COL_LENGTH(N'dbo.ModelliPreventivoRighe', N'IdTipoRiga') IS NULL
BEGIN
    THROW 52100, 'TEC-010: schema richiesto non disponibile. Applicare prima TEC-008.', 1;
END;
GO

IF EXISTS
(
    SELECT 1
    FROM dbo.ModelliPreventivo AS modello
    LEFT JOIN dbo.Clienti AS cliente ON cliente.IdCliente = modello.IdCliente
    WHERE modello.IdCliente IS NOT NULL
      AND cliente.IdCliente IS NULL
)
BEGIN
    SELECT modello.IdModelloPreventivo, modello.IdCliente
    FROM dbo.ModelliPreventivo AS modello
    LEFT JOIN dbo.Clienti AS cliente ON cliente.IdCliente = modello.IdCliente
    WHERE modello.IdCliente IS NOT NULL
      AND cliente.IdCliente IS NULL;

    THROW 52101, 'TEC-010: modelli con cliente non valido. Correggere i dati e rieseguire.', 1;
END;
GO

IF EXISTS
(
    SELECT 1
    FROM dbo.ModelliPreventivoRighe AS riga
    LEFT JOIN dbo.ModelliPreventivo AS modello
        ON modello.IdModelloPreventivo = riga.IdModelloPreventivo
    LEFT JOIN dbo.TipiRigaPreventivo AS tipo
        ON tipo.IdTipoRiga = riga.IdTipoRiga
    LEFT JOIN dbo.Articoli AS articolo
        ON articolo.IdArticolo = riga.IdArticolo
    LEFT JOIN dbo.ModelliCiclo AS ciclo
        ON ciclo.IdModelloCiclo = riga.IdModelloCiclo
    WHERE modello.IdModelloPreventivo IS NULL
       OR tipo.IdTipoRiga IS NULL
       OR (riga.IdArticolo IS NOT NULL AND articolo.IdArticolo IS NULL)
       OR (riga.IdModelloCiclo IS NOT NULL AND ciclo.IdModelloCiclo IS NULL)
)
BEGIN
    SELECT
        riga.IdRigaModelloPreventivo,
        riga.IdModelloPreventivo,
        riga.IdTipoRiga,
        riga.IdArticolo,
        riga.IdModelloCiclo
    FROM dbo.ModelliPreventivoRighe AS riga
    LEFT JOIN dbo.ModelliPreventivo AS modello
        ON modello.IdModelloPreventivo = riga.IdModelloPreventivo
    LEFT JOIN dbo.TipiRigaPreventivo AS tipo
        ON tipo.IdTipoRiga = riga.IdTipoRiga
    LEFT JOIN dbo.Articoli AS articolo
        ON articolo.IdArticolo = riga.IdArticolo
    LEFT JOIN dbo.ModelliCiclo AS ciclo
        ON ciclo.IdModelloCiclo = riga.IdModelloCiclo
    WHERE modello.IdModelloPreventivo IS NULL
       OR tipo.IdTipoRiga IS NULL
       OR (riga.IdArticolo IS NOT NULL AND articolo.IdArticolo IS NULL)
       OR (riga.IdModelloCiclo IS NOT NULL AND ciclo.IdModelloCiclo IS NULL);

    THROW 52102, 'TEC-010: righe modello con riferimenti non validi. Correggere i dati e rieseguire.', 1;
END;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'dbo.ModelliPreventivo')
      AND COL_NAME(fkc.parent_object_id, fkc.parent_column_id) = N'IdCliente'
)
BEGIN
    ALTER TABLE dbo.ModelliPreventivo WITH CHECK
        ADD CONSTRAINT FK_ModelliPreventivo_Clienti_TEC010
        FOREIGN KEY (IdCliente) REFERENCES dbo.Clienti (IdCliente);
END;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'dbo.ModelliPreventivoRighe')
      AND COL_NAME(fkc.parent_object_id, fkc.parent_column_id) = N'IdModelloPreventivo'
)
BEGIN
    ALTER TABLE dbo.ModelliPreventivoRighe WITH CHECK
        ADD CONSTRAINT FK_ModelliPreventivoRighe_Modello_TEC010
        FOREIGN KEY (IdModelloPreventivo)
        REFERENCES dbo.ModelliPreventivo (IdModelloPreventivo);
END;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'dbo.ModelliPreventivoRighe')
      AND COL_NAME(fkc.parent_object_id, fkc.parent_column_id) = N'IdTipoRiga'
)
BEGIN
    ALTER TABLE dbo.ModelliPreventivoRighe WITH CHECK
        ADD CONSTRAINT FK_ModelliPreventivoRighe_Tipo_TEC010
        FOREIGN KEY (IdTipoRiga) REFERENCES dbo.TipiRigaPreventivo (IdTipoRiga);
END;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'dbo.ModelliPreventivoRighe')
      AND COL_NAME(fkc.parent_object_id, fkc.parent_column_id) = N'IdArticolo'
)
BEGIN
    ALTER TABLE dbo.ModelliPreventivoRighe WITH CHECK
        ADD CONSTRAINT FK_ModelliPreventivoRighe_Articolo_TEC010
        FOREIGN KEY (IdArticolo) REFERENCES dbo.Articoli (IdArticolo);
END;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'dbo.ModelliPreventivoRighe')
      AND COL_NAME(fkc.parent_object_id, fkc.parent_column_id) = N'IdModelloCiclo'
)
BEGIN
    ALTER TABLE dbo.ModelliPreventivoRighe WITH CHECK
        ADD CONSTRAINT FK_ModelliPreventivoRighe_Ciclo_TEC010
        FOREIGN KEY (IdModelloCiclo) REFERENCES dbo.ModelliCiclo (IdModelloCiclo);
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Modelli_Elenco
    @Ricerca NVARCHAR(300) = NULL,
    @IdCliente INT = NULL,
    @SoloAttivi BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Filtro NVARCHAR(300) = NULLIF(LTRIM(RTRIM(@Ricerca)), N'');

    SELECT
        modello.IdModelloPreventivo,
        modello.CodiceModelloPreventivo,
        modello.Descrizione,
        modello.IdCliente,
        COALESCE(cliente.RagioneSociale, N'') AS Cliente,
        COALESCE(modello.Oggetto, N'') AS Oggetto,
        modello.Attivo,
        CONVERT(INT, COUNT(riga.IdRigaModelloPreventivo)) AS NumeroRighe
    FROM dbo.ModelliPreventivo AS modello
    LEFT JOIN dbo.Clienti AS cliente ON cliente.IdCliente = modello.IdCliente
    LEFT JOIN dbo.ModelliPreventivoRighe AS riga
        ON riga.IdModelloPreventivo = modello.IdModelloPreventivo
    WHERE (@SoloAttivi IS NULL OR modello.Attivo = @SoloAttivi)
      AND (@IdCliente IS NULL OR modello.IdCliente = @IdCliente)
      AND
      (
          @Filtro IS NULL
          OR modello.CodiceModelloPreventivo LIKE N'%' + @Filtro + N'%'
          OR modello.Descrizione LIKE N'%' + @Filtro + N'%'
          OR modello.Oggetto LIKE N'%' + @Filtro + N'%'
          OR cliente.RagioneSociale LIKE N'%' + @Filtro + N'%'
      )
    GROUP BY
        modello.IdModelloPreventivo,
        modello.CodiceModelloPreventivo,
        modello.Descrizione,
        modello.IdCliente,
        cliente.RagioneSociale,
        modello.Oggetto,
        modello.Attivo
    ORDER BY modello.CodiceModelloPreventivo;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Modelli_Dettaglio
    @IdModelloPreventivo INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        modello.IdModelloPreventivo,
        modello.CodiceModelloPreventivo,
        modello.Descrizione,
        modello.IdCliente,
        COALESCE(cliente.RagioneSociale, N'') AS Cliente,
        modello.Oggetto,
        modello.Note,
        modello.Attivo,
        modello.DataCreazione,
        modello.DataModifica
    FROM dbo.ModelliPreventivo AS modello
    LEFT JOIN dbo.Clienti AS cliente ON cliente.IdCliente = modello.IdCliente
    WHERE modello.IdModelloPreventivo = @IdModelloPreventivo;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Modelli_Crea
    @CodiceModelloPreventivo NVARCHAR(50),
    @Descrizione NVARCHAR(150),
    @IdCliente INT = NULL,
    @Oggetto NVARCHAR(250) = NULL,
    @Note NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NULLIF(LTRIM(RTRIM(@CodiceModelloPreventivo)), N'') IS NULL
        THROW 52110, 'Inserire il codice del modello preventivo.', 1;
    IF NULLIF(LTRIM(RTRIM(@Descrizione)), N'') IS NULL
        THROW 52111, 'Inserire la descrizione del modello preventivo.', 1;
    IF @IdCliente IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM dbo.Clienti WHERE IdCliente = @IdCliente)
        THROW 52112, 'Il cliente selezionato non esiste.', 1;

    INSERT INTO dbo.ModelliPreventivo
    (
        CodiceModelloPreventivo,
        Descrizione,
        IdCliente,
        Oggetto,
        Note,
        Attivo
    )
    VALUES
    (
        LTRIM(RTRIM(@CodiceModelloPreventivo)),
        LTRIM(RTRIM(@Descrizione)),
        @IdCliente,
        NULLIF(LTRIM(RTRIM(@Oggetto)), N''),
        NULLIF(LTRIM(RTRIM(@Note)), N''),
        1
    );

    SELECT CONVERT(INT, SCOPE_IDENTITY());
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Modelli_Aggiorna
    @IdModelloPreventivo INT,
    @CodiceModelloPreventivo NVARCHAR(50),
    @Descrizione NVARCHAR(150),
    @IdCliente INT = NULL,
    @Oggetto NVARCHAR(250) = NULL,
    @Note NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
       (SELECT 1 FROM dbo.ModelliPreventivo WHERE IdModelloPreventivo = @IdModelloPreventivo)
        THROW 52113, 'Il modello preventivo non esiste.', 1;
    IF NULLIF(LTRIM(RTRIM(@CodiceModelloPreventivo)), N'') IS NULL
        THROW 52110, 'Inserire il codice del modello preventivo.', 1;
    IF NULLIF(LTRIM(RTRIM(@Descrizione)), N'') IS NULL
        THROW 52111, 'Inserire la descrizione del modello preventivo.', 1;
    IF @IdCliente IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM dbo.Clienti WHERE IdCliente = @IdCliente)
        THROW 52112, 'Il cliente selezionato non esiste.', 1;

    UPDATE dbo.ModelliPreventivo
    SET CodiceModelloPreventivo = LTRIM(RTRIM(@CodiceModelloPreventivo)),
        Descrizione = LTRIM(RTRIM(@Descrizione)),
        IdCliente = @IdCliente,
        Oggetto = NULLIF(LTRIM(RTRIM(@Oggetto)), N''),
        Note = NULLIF(LTRIM(RTRIM(@Note)), N''),
        DataModifica = SYSDATETIME()
    WHERE IdModelloPreventivo = @IdModelloPreventivo;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Modelli_ImpostaAttivo
    @IdModelloPreventivo INT,
    @Attivo BIT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.ModelliPreventivo
    SET Attivo = @Attivo,
        DataModifica = SYSDATETIME()
    WHERE IdModelloPreventivo = @IdModelloPreventivo;

    IF @@ROWCOUNT = 0
        THROW 52113, 'Il modello preventivo non esiste.', 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Modelli_Righe_Elenco
    @IdModelloPreventivo INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        riga.IdRigaModelloPreventivo,
        riga.IdModelloPreventivo,
        riga.RigaNr,
        riga.IdTipoRiga,
        tipo.Descrizione AS TipoRiga,
        riga.IdArticolo,
        CASE
            WHEN articolo.IdArticolo IS NULL THEN N''
            ELSE articolo.CodiceArticolo + N' - ' + articolo.Descrizione
        END AS Articolo,
        riga.IdModelloCiclo,
        CASE
            WHEN ciclo.IdModelloCiclo IS NULL THEN N''
            ELSE ciclo.CodiceModelloCiclo + N' - ' + ciclo.Descrizione
        END AS ModelloCiclo,
        riga.DescrizioneVoce,
        riga.Quantita,
        riga.PrezzoUnitarioVendita,
        riga.Note
    FROM dbo.ModelliPreventivoRighe AS riga
    INNER JOIN dbo.TipiRigaPreventivo AS tipo ON tipo.IdTipoRiga = riga.IdTipoRiga
    LEFT JOIN dbo.Articoli AS articolo ON articolo.IdArticolo = riga.IdArticolo
    LEFT JOIN dbo.ModelliCiclo AS ciclo ON ciclo.IdModelloCiclo = riga.IdModelloCiclo
    WHERE riga.IdModelloPreventivo = @IdModelloPreventivo
    ORDER BY riga.RigaNr;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Modelli_Righe_Dettaglio
    @IdRigaModelloPreventivo INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        riga.IdRigaModelloPreventivo,
        riga.IdModelloPreventivo,
        riga.RigaNr,
        riga.IdTipoRiga,
        tipo.Descrizione AS TipoRiga,
        riga.IdArticolo,
        CASE
            WHEN articolo.IdArticolo IS NULL THEN N''
            ELSE articolo.CodiceArticolo + N' - ' + articolo.Descrizione
        END AS Articolo,
        riga.IdModelloCiclo,
        CASE
            WHEN ciclo.IdModelloCiclo IS NULL THEN N''
            ELSE ciclo.CodiceModelloCiclo + N' - ' + ciclo.Descrizione
        END AS ModelloCiclo,
        riga.DescrizioneVoce,
        riga.Quantita,
        riga.PrezzoUnitarioVendita,
        riga.Note
    FROM dbo.ModelliPreventivoRighe AS riga
    INNER JOIN dbo.TipiRigaPreventivo AS tipo ON tipo.IdTipoRiga = riga.IdTipoRiga
    LEFT JOIN dbo.Articoli AS articolo ON articolo.IdArticolo = riga.IdArticolo
    LEFT JOIN dbo.ModelliCiclo AS ciclo ON ciclo.IdModelloCiclo = riga.IdModelloCiclo
    WHERE riga.IdRigaModelloPreventivo = @IdRigaModelloPreventivo;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Modelli_Righe_Crea
    @IdModelloPreventivo INT,
    @RigaNr INT,
    @IdTipoRiga INT,
    @IdArticolo INT = NULL,
    @IdModelloCiclo INT = NULL,
    @DescrizioneVoce NVARCHAR(250),
    @Quantita DECIMAL(18,4),
    @PrezzoUnitarioVendita DECIMAL(18,4),
    @Note NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
       (SELECT 1 FROM dbo.ModelliPreventivo WHERE IdModelloPreventivo = @IdModelloPreventivo)
        THROW 52113, 'Il modello preventivo non esiste.', 1;
    IF @RigaNr <= 0
        THROW 52120, 'Il numero riga deve essere maggiore di zero.', 1;
    IF NULLIF(LTRIM(RTRIM(@DescrizioneVoce)), N'') IS NULL
        THROW 52121, 'Inserire la descrizione della riga.', 1;
    IF @Quantita <= 0
        THROW 52122, 'La quantita deve essere maggiore di zero.', 1;
    IF @PrezzoUnitarioVendita < 0
        THROW 52123, 'Il prezzo unitario non puo essere negativo.', 1;

    DECLARE @RigaArticolo BIT;
    DECLARE @ObbligaArticolo BIT;

    SELECT
        @RigaArticolo = RigaArticolo,
        @ObbligaArticolo = ObbligaArticolo
    FROM dbo.TipiRigaPreventivo
    WHERE IdTipoRiga = @IdTipoRiga
      AND Attiva = 1;

    IF @RigaArticolo IS NULL
        THROW 52124, 'Il tipo riga selezionato non e disponibile.', 1;
    IF @RigaArticolo = 0 AND (@IdArticolo IS NOT NULL OR @IdModelloCiclo IS NOT NULL)
        THROW 52125, 'Il tipo riga selezionato non prevede articolo o modello ciclo.', 1;
    IF @RigaArticolo = 1 AND @ObbligaArticolo = 1 AND @IdArticolo IS NULL
        THROW 52126, 'Selezionare un articolo.', 1;
    IF @IdArticolo IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM dbo.Articoli WHERE IdArticolo = @IdArticolo AND Attivo = 1)
        THROW 52127, 'L''articolo selezionato non e disponibile.', 1;
    IF @IdModelloCiclo IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM dbo.ModelliCiclo WHERE IdModelloCiclo = @IdModelloCiclo AND Attivo = 1)
        THROW 52128, 'Il modello ciclo selezionato non e disponibile.', 1;

    INSERT INTO dbo.ModelliPreventivoRighe
    (
        IdModelloPreventivo,
        RigaNr,
        IdTipoRiga,
        IdArticolo,
        IdModelloCiclo,
        DescrizioneVoce,
        Quantita,
        PrezzoUnitarioVendita,
        Note
    )
    VALUES
    (
        @IdModelloPreventivo,
        @RigaNr,
        @IdTipoRiga,
        @IdArticolo,
        @IdModelloCiclo,
        LTRIM(RTRIM(@DescrizioneVoce)),
        @Quantita,
        @PrezzoUnitarioVendita,
        NULLIF(LTRIM(RTRIM(@Note)), N'')
    );

    SELECT CONVERT(INT, SCOPE_IDENTITY());
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Modelli_Righe_Aggiorna
    @IdRigaModelloPreventivo INT,
    @RigaNr INT,
    @IdTipoRiga INT,
    @IdArticolo INT = NULL,
    @IdModelloCiclo INT = NULL,
    @DescrizioneVoce NVARCHAR(250),
    @Quantita DECIMAL(18,4),
    @PrezzoUnitarioVendita DECIMAL(18,4),
    @Note NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
       (SELECT 1 FROM dbo.ModelliPreventivoRighe WHERE IdRigaModelloPreventivo = @IdRigaModelloPreventivo)
        THROW 52129, 'La riga modello non esiste.', 1;
    IF @RigaNr <= 0
        THROW 52120, 'Il numero riga deve essere maggiore di zero.', 1;
    IF NULLIF(LTRIM(RTRIM(@DescrizioneVoce)), N'') IS NULL
        THROW 52121, 'Inserire la descrizione della riga.', 1;
    IF @Quantita <= 0
        THROW 52122, 'La quantita deve essere maggiore di zero.', 1;
    IF @PrezzoUnitarioVendita < 0
        THROW 52123, 'Il prezzo unitario non puo essere negativo.', 1;

    DECLARE @RigaArticolo BIT;
    DECLARE @ObbligaArticolo BIT;

    SELECT
        @RigaArticolo = RigaArticolo,
        @ObbligaArticolo = ObbligaArticolo
    FROM dbo.TipiRigaPreventivo
    WHERE IdTipoRiga = @IdTipoRiga
      AND Attiva = 1;

    IF @RigaArticolo IS NULL
        THROW 52124, 'Il tipo riga selezionato non e disponibile.', 1;
    IF @RigaArticolo = 0 AND (@IdArticolo IS NOT NULL OR @IdModelloCiclo IS NOT NULL)
        THROW 52125, 'Il tipo riga selezionato non prevede articolo o modello ciclo.', 1;
    IF @RigaArticolo = 1 AND @ObbligaArticolo = 1 AND @IdArticolo IS NULL
        THROW 52126, 'Selezionare un articolo.', 1;
    IF @IdArticolo IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM dbo.Articoli WHERE IdArticolo = @IdArticolo AND Attivo = 1)
        THROW 52127, 'L''articolo selezionato non e disponibile.', 1;
    IF @IdModelloCiclo IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM dbo.ModelliCiclo WHERE IdModelloCiclo = @IdModelloCiclo AND Attivo = 1)
        THROW 52128, 'Il modello ciclo selezionato non e disponibile.', 1;

    UPDATE dbo.ModelliPreventivoRighe
    SET RigaNr = @RigaNr,
        IdTipoRiga = @IdTipoRiga,
        IdArticolo = @IdArticolo,
        IdModelloCiclo = @IdModelloCiclo,
        DescrizioneVoce = LTRIM(RTRIM(@DescrizioneVoce)),
        Quantita = @Quantita,
        PrezzoUnitarioVendita = @PrezzoUnitarioVendita,
        Note = NULLIF(LTRIM(RTRIM(@Note)), N'')
    WHERE IdRigaModelloPreventivo = @IdRigaModelloPreventivo;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Modelli_Righe_Elimina
    @IdRigaModelloPreventivo INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM dbo.ModelliPreventivoRighe
    WHERE IdRigaModelloPreventivo = @IdRigaModelloPreventivo;

    IF @@ROWCOUNT = 0
        THROW 52129, 'La riga modello non esiste.', 1;
END;
GO
