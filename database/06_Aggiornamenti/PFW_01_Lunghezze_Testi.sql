-- Decisioni 377-381: allineamento dei parametri alle colonne esistenti.
-- Non modifica tabelle o dati applicativi. Eseguire sul database previsto.
-- SHA-256: payload tra i marcatori, trim e righe LF, codifica UTF-8.
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @Versione INT = 2026112505;
    DECLARE @Codice NVARCHAR(50) = N'PFW-LUNGHEZZE-TESTI';
    DECLARE @Script NVARCHAR(260) = N'PFW_01_Lunghezze_Testi.sql';
    DECLARE @Impronta CHAR(64) = '6F9A0CFBC4FDC806226C7A242428DEA08F73C5DD7DBA91C30ED161F2278717F5';
    IF OBJECT_ID(N'dbo.VersioniSchema', N'U') IS NULL
        THROW 54501, 'Registro VersioniSchema assente.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.VersioniSchema WITH (UPDLOCK, HOLDLOCK)
                   WHERE Versione = 2026112504 AND CodiceIntervento = N'TEC-019-UTENTI')
        THROW 54502, 'Versione prerequisito 2026112504 non installata.', 1;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione > @Versione)
        THROW 54503, 'Il database contiene una versione successiva.', 1;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione = @Versione
               AND CodiceIntervento = @Codice AND NomeScript = @Script AND ImprontaSha256 = @Impronta)
    BEGIN
        COMMIT TRANSACTION;
        RETURN;
    END;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione = @Versione
               OR CodiceIntervento = @Codice OR NomeScript = @Script)
        THROW 54504, 'Versione gia registrata con metadati differenti.', 1;

/* PAYLOAD PFW-LUNGHEZZE-TESTI START */
    DECLARE @Limiti TABLE
    (
        Id INT IDENTITY PRIMARY KEY,
        Procedura SYSNAME NOT NULL,
        Parametro SYSNAME NOT NULL,
        Tabella SYSNAME NOT NULL,
        Colonna SYSNAME NOT NULL,
        Massimo INT NOT NULL,
        Precedente INT NOT NULL
    );
    INSERT @Limiti(Procedura, Parametro, Tabella, Colonna, Massimo, Precedente) VALUES
    (N'Clienti_Crea', N'@CodiceCliente', N'Clienti', N'CodiceCliente', 30, 50),
    (N'Clienti_Crea', N'@RagioneSociale', N'Clienti', N'RagioneSociale', 150, 200),
    (N'Clienti_Crea', N'@PartitaIVA', N'Clienti', N'PartitaIVA', 20, 30),
    (N'Clienti_Crea', N'@CodiceFiscale', N'Clienti', N'CodiceFiscale', 20, 30),
    (N'Clienti_Crea', N'@Indirizzo', N'Clienti', N'Indirizzo', 150, 200),
    (N'Clienti_Crea', N'@Email', N'Clienti', N'Email', 150, 200),
    (N'Clienti_Aggiorna', N'@CodiceCliente', N'Clienti', N'CodiceCliente', 30, 50),
    (N'Clienti_Aggiorna', N'@RagioneSociale', N'Clienti', N'RagioneSociale', 150, 200),
    (N'Clienti_Aggiorna', N'@PartitaIVA', N'Clienti', N'PartitaIVA', 20, 30),
    (N'Clienti_Aggiorna', N'@CodiceFiscale', N'Clienti', N'CodiceFiscale', 20, 30),
    (N'Clienti_Aggiorna', N'@Indirizzo', N'Clienti', N'Indirizzo', 150, 200),
    (N'Clienti_Aggiorna', N'@Email', N'Clienti', N'Email', 150, 200),
    (N'Preventivi_Righe_Crea', N'@DescrizioneVoce', N'PreventiviRighe', N'DescrizioneVoce', 250, 500),
    (N'Preventivi_Righe_Componenti_Crea', N'@DescrizioneNodo', N'PreventiviRigheComponenti', N'DescrizioneNodo', 200, 400),
    (N'Preventivi_Righe_Materiali_Crea', N'@DescrizioneMateriale', N'PreventiviRigheMateriali', N'DescrizioneMateriale', 200, 400),
    (N'Preventivi_Righe_Materiali_Crea', N'@TipoMateriale', N'PreventiviRigheMateriali', N'TipoMateriale', 30, 60),
    (N'Preventivi_Righe_Materiali_Crea', N'@UM', N'PreventiviRigheMateriali', N'UM', 10, 20),
    (N'Preventivi_Righe_Lavorazioni_Crea', N'@DescrizioneLavorazione', N'PreventiviRigheLavorazioni', N'DescrizioneLavorazione', 150, 300),
    (N'Preventivi_Varianti_Crea', N'@CodiceVariante', N'PreventiviVarianti', N'CodiceVariante', 30, 60),
    (N'Preventivi_Varianti_Crea', N'@DescrizioneVariante', N'PreventiviVarianti', N'DescrizioneVariante', 250, 500);

    DECLARE @Id INT = 1, @Ultimo INT = (SELECT MAX(Id) FROM @Limiti);
    DECLARE @Procedura SYSNAME, @Parametro SYSNAME, @Tabella SYSNAME, @Colonna SYSNAME;
    DECLARE @Massimo INT, @Precedente INT, @Attuale INT, @Oggetto INT;
    DECLARE @Definizione NVARCHAR(MAX), @Messaggio NVARCHAR(2048);
    DECLARE @Pos INT, @Tipo INT, @Apre INT, @Chiude INT, @Intestazione INT;
    WHILE @Id <= @Ultimo
    BEGIN
        SELECT @Procedura = Procedura, @Parametro = Parametro, @Tabella = Tabella,
               @Colonna = Colonna, @Massimo = Massimo, @Precedente = Precedente
        FROM @Limiti WHERE Id = @Id;
        IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.' + @Tabella)
                       AND name = @Colonna AND system_type_id = TYPE_ID(N'nvarchar') AND max_length = 2 * @Massimo)
        BEGIN
            SET @Messaggio = N'Colonna non allineata allo schema previsto: dbo.' + @Tabella + N'.' + @Colonna;
            THROW 54505, @Messaggio, 1;
        END;
        SET @Oggetto = OBJECT_ID(N'dbo.' + @Procedura, N'P');
        SET @Attuale = NULL;
        SELECT @Attuale = max_length FROM sys.parameters
        WHERE object_id = @Oggetto AND name = @Parametro AND system_type_id = TYPE_ID(N'nvarchar');
        IF @Attuale IS NULL OR @Attuale NOT IN (2 * @Massimo, 2 * @Precedente)
        BEGIN
            SET @Messaggio = N'Parametro assente o inatteso: dbo.' + @Procedura + N' ' + @Parametro;
            THROW 54506, @Messaggio, 1;
        END;
        IF @Attuale <> 2 * @Massimo
        BEGIN
            -- Conserva integralmente la logica della procedura installata:
            -- modifica soltanto la dimensione della dichiarazione verificata.
            SET @Definizione = OBJECT_DEFINITION(@Oggetto);
            IF @Definizione IS NULL THROW 54507, 'Definizione procedura non leggibile.', 1;
            SET @Pos = CHARINDEX(@Parametro, @Definizione);
            SET @Tipo = CHARINDEX(N'NVARCHAR', UPPER(@Definizione), @Pos + LEN(@Parametro));
            IF @Pos = 0 OR @Tipo = 0
                THROW 54508, 'Dichiarazione parametro non trovata.', 1;
            IF
               REPLACE(REPLACE(REPLACE(REPLACE(SUBSTRING(@Definizione, @Pos + LEN(@Parametro),
                   @Tipo - @Pos - LEN(@Parametro)), N' ', N''), CHAR(9), N''), CHAR(13), N''), CHAR(10), N'') <> N''
                THROW 54508, 'Dichiarazione parametro inattesa: nessuna modifica applicata.', 1;
            SET @Apre = CHARINDEX(N'(', @Definizione, @Tipo);
            SET @Chiude = CHARINDEX(N')', @Definizione, @Apre);
            IF @Apre = 0 OR @Chiude = 0
                THROW 54508, 'Dimensione parametro non trovata.', 1;
            IF ISNULL(TRY_CONVERT(INT, SUBSTRING(@Definizione, @Apre + 1, @Chiude - @Apre - 1)), -1) <> @Precedente
                THROW 54508, 'Dimensione parametro inattesa: nessuna modifica applicata.', 1;
            SET @Definizione = STUFF(@Definizione, @Apre + 1, @Chiude - @Apre - 1, CONVERT(NVARCHAR(10), @Massimo));
            SET @Intestazione = CHARINDEX(N'PROCEDURE', UPPER(@Definizione));
            IF @Intestazione = 0 THROW 54508, 'Intestazione procedura inattesa.', 1;
            SET @Definizione = N'CREATE OR ALTER ' + SUBSTRING(@Definizione, @Intestazione, LEN(@Definizione));
            EXEC sys.sp_executesql @Definizione;
            IF NOT EXISTS (SELECT 1 FROM sys.parameters WHERE object_id = @Oggetto
                           AND name = @Parametro AND max_length = 2 * @Massimo)
                THROW 54509, 'Verifica finale parametro non superata.', 1;
        END;
        SET @Id += 1;
    END;
/* PAYLOAD PFW-LUNGHEZZE-TESTI END */

    INSERT dbo.VersioniSchema(Versione, CodiceIntervento, NomeScript, Descrizione, ImprontaSha256)
    VALUES(@Versione, @Codice, @Script, N'Allineamento lunghezze testi di Clienti e Preventivi senza modificare colonne o dati.', @Impronta);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
