-- Decisioni 357-361. Generazione transazionale degli acquisti dai preventivi.
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @Versione INT = 2026112402;
    DECLARE @Codice NVARCHAR(50) = N'TEC-018-GENERAZIONE';
    DECLARE @Script NVARCHAR(260) = N'TEC-018_03_Generazione_Da_Preventivi.sql';
    DECLARE @Impronta CHAR(64) = 'ECE93AD4BCAF39189B4658D2CE607E01FE11A44067F450F36B57700A42873CE0';
    IF NOT EXISTS (SELECT 1 FROM dbo.VersioniSchema WITH (UPDLOCK, HOLDLOCK)
                   WHERE Versione = 2026112401 AND CodiceIntervento = N'TEC-018-INVIO')
        THROW 53896, 'Versione prerequisito 2026112401 non installata.', 1;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione > @Versione)
        THROW 53897, 'Il database contiene una versione successiva.', 1;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione = @Versione AND CodiceIntervento = @Codice
               AND NomeScript = @Script AND ImprontaSha256 = @Impronta)
    BEGIN
        COMMIT TRANSACTION;
        RETURN;
    END;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione = @Versione OR CodiceIntervento = @Codice OR NomeScript = @Script)
        THROW 53898, 'Versione gia registrata con metadati differenti.', 1;

/* PAYLOAD TEC-018-GENERAZIONE START */
    EXEC sys.sp_executesql N'ALTER TABLE dbo.OrdiniFornitoriRighe ADD
    IdRigaMatPrev INT NULL, IdRigaLavPrev INT NULL, IdRigaCompPrev INT NULL;
ALTER TABLE dbo.OrdiniFornitoriRighe ADD
    CONSTRAINT FK_OrdiniRighe_MaterialePreventivo FOREIGN KEY (IdRigaMatPrev) REFERENCES dbo.PreventiviRigheMateriali(IdRigaMatPrev),
    CONSTRAINT FK_OrdiniRighe_LavorazionePreventivo FOREIGN KEY (IdRigaLavPrev) REFERENCES dbo.PreventiviRigheLavorazioni(IdRigaLavPrev),
    CONSTRAINT FK_OrdiniRighe_ComponentePreventivo FOREIGN KEY (IdRigaCompPrev) REFERENCES dbo.PreventiviRigheComponenti(IdRigaCompPrev),
    CONSTRAINT CK_OrdiniRighe_Origine CHECK (IdRigaMatPrev IS NULL OR IdRigaLavPrev IS NULL);
CREATE INDEX IX_OrdiniRighe_MaterialePreventivo ON dbo.OrdiniFornitoriRighe(IdRigaMatPrev) INCLUDE (IdOrdineFornitore, Quantita);
CREATE INDEX IX_OrdiniRighe_LavorazionePreventivo ON dbo.OrdiniFornitoriRighe(IdRigaLavPrev) INCLUDE (IdOrdineFornitore, Quantita);
CREATE TABLE dbo.OrdiniFornitoriGenerazioni
(
    Richiesta UNIQUEIDENTIFIER NOT NULL PRIMARY KEY, Impronta BINARY(32) NOT NULL,
    Utente NVARCHAR(256) NOT NULL, CreatoIl DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    OrdiniJson NVARCHAR(MAX) NOT NULL CHECK (ISJSON(OrdiniJson) = 1)
);';
    EXEC sys.sp_executesql N'CREATE OR ALTER FUNCTION dbo.OrdiniFornitori_AcquistiPreventivo(@IdPreventivo INT, @IdRigaPreventivo INT)
RETURNS TABLE AS RETURN
WITH Origini AS
(
    SELECT N''Materiale'' AS Tipo, m.IdRigaMatPrev AS IdOrigine, m.IdRigaPreventivo,
        m.IdRigaCompPrev, m.IdNodoDistinta, m.IdMateriale AS IdAnagrafica,
        m.DescrizioneMateriale AS Descrizione, m.UM, m.Quantita,
        CAST(m.CostoUnitario AS DECIMAL(18,4)) AS PrezzoProposto, m.IdFornitoreSuggerito
    FROM dbo.PreventiviRigheMateriali m WHERE m.DaAcquistare = 1
    UNION ALL
    SELECT N''Lavorazione'', l.IdRigaLavPrev, l.IdRigaPreventivo,
        l.IdRigaCompPrev, l.IdNodoDistinta, l.IdLavorazione, l.DescrizioneLavorazione,
        CAST(NULL AS NVARCHAR(10)), l.Quantita,
        CAST(ROUND(ROUND((l.TempoSetupMin + l.TempoPezzoMin * l.Quantita) / 60.0 * l.CostoOrario + l.CostoFisso, 2)
            / NULLIF(l.Quantita,0),4) AS DECIMAL(18,4)), l.IdFornitoreSuggerito
    FROM dbo.PreventiviRigheLavorazioni l WHERE l.DaAcquistareEsterno = 1
)
SELECT s.*, p.IdPreventivo, p.RigaNr, p.IdVariantePreventivo, c.DescrizioneNodo AS Componente,
    COALESCE(o.GiaOrdinata,0) AS GiaOrdinata,
    s.Quantita - COALESCE(o.GiaOrdinata,0) AS Residuo,
    CONVERT(VARCHAR(64), HASHBYTES(''SHA2_256'', CONCAT(s.Tipo,N''|'',s.IdOrigine,N''|'',
        s.IdRigaPreventivo,N''|'',s.IdRigaCompPrev,N''|'',s.IdNodoDistinta,N''|'',s.IdAnagrafica,N''|'',
        DATALENGTH(s.Descrizione),N'':'',s.Descrizione,N''|'',DATALENGTH(s.UM),N'':'',s.UM,N''|'',
        s.Quantita,N''|'',s.PrezzoProposto,N''|'',s.IdFornitoreSuggerito,N''|'',p.IdPreventivo,N''|'',
        p.RigaNr,N''|'',p.IdVariantePreventivo,N''|'',DATALENGTH(c.DescrizioneNodo),N'':'',c.DescrizioneNodo)), 2) AS Impronta,
    CAST(CASE WHEN EXISTS
    (
        SELECT 1 FROM dbo.OrdiniFornitoriRighe x JOIN dbo.OrdiniFornitori h ON h.IdOrdineFornitore=x.IdOrdineFornitore
        WHERE h.Stato <> N''Annullato'' AND x.IdRigaPreventivo=s.IdRigaPreventivo AND x.TipoRiga=s.Tipo
            AND x.IdRigaMatPrev IS NULL AND x.IdRigaLavPrev IS NULL
            AND (x.IdNodoDistinta=s.IdNodoDistinta OR x.IdNodoDistinta IS NULL OR s.IdNodoDistinta IS NULL)
            AND (CASE WHEN s.Tipo=N''Materiale'' THEN x.IdMateriale ELSE x.IdLavorazione END=s.IdAnagrafica
                 OR s.IdAnagrafica IS NULL OR CASE WHEN s.Tipo=N''Materiale'' THEN x.IdMateriale ELSE x.IdLavorazione END IS NULL)
    ) THEN 1 ELSE 0 END AS BIT) AS DaRiconciliare
FROM Origini s JOIN dbo.PreventiviRighe p ON p.IdRigaPreventivo=s.IdRigaPreventivo
LEFT JOIN dbo.PreventiviRigheComponenti c ON c.IdRigaCompPrev=s.IdRigaCompPrev
OUTER APPLY
(
    SELECT CAST(SUM(x.Quantita) AS DECIMAL(28,4)) AS GiaOrdinata FROM dbo.OrdiniFornitoriRighe x
    JOIN dbo.OrdiniFornitori h ON h.IdOrdineFornitore=x.IdOrdineFornitore
    WHERE h.Stato <> N''Annullato''
      AND ((s.Tipo=N''Materiale'' AND x.IdRigaMatPrev=s.IdOrigine)
        OR (s.Tipo=N''Lavorazione'' AND x.IdRigaLavPrev=s.IdOrigine))
) o
WHERE p.IdPreventivo=@IdPreventivo AND (@IdRigaPreventivo IS NULL OR p.IdRigaPreventivo=@IdRigaPreventivo);';
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.OrdiniFornitori_Generazione_Anteprima @IdPreventivo INT, @IdRigaPreventivo INT=NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM dbo.OrdiniFornitori_AcquistiPreventivo(@IdPreventivo,@IdRigaPreventivo)
    ORDER BY RigaNr, IdVariantePreventivo, IdRigaCompPrev, Tipo, IdOrigine;
END;';
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.OrdiniFornitori_Generazione_Conferma
    @IdPreventivo INT, @IdRigaPreventivo INT=NULL, @Richiesta UNIQUEIDENTIFIER,
    @DataOrdine DATE, @Selezione NVARCHAR(MAX), @Utente NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF @Richiesta IS NULL OR @DataOrdine IS NULL OR NULLIF(LTRIM(RTRIM(@Utente)),N'''') IS NULL OR ISJSON(@Selezione)<>1
        THROW 54130, ''Richiesta di generazione non valida.'', 1;
    DECLARE @Input TABLE(Tipo NVARCHAR(20), IdOrigine INT, Impronta VARCHAR(64), IdFornitore INT,
        Quantita DECIMAL(18,4), PrezzoUnitario DECIMAL(18,4));
    INSERT @Input SELECT * FROM OPENJSON(@Selezione) WITH
        (Tipo NVARCHAR(20),IdOrigine INT,Impronta VARCHAR(64),IdFornitore INT,Quantita DECIMAL(18,4),PrezzoUnitario DECIMAL(18,4));
    IF NOT EXISTS(SELECT 1 FROM @Input) OR (SELECT COUNT(*) FROM @Input)>500
        OR EXISTS(SELECT 1 FROM @Input WHERE Tipo IS NULL OR Tipo NOT IN(N''Materiale'',N''Lavorazione'')
            OR IdOrigine IS NULL OR IdOrigine<=0 OR LEN(Impronta)<>64 OR Impronta IS NULL
            OR IdFornitore IS NULL OR Quantita IS NULL OR Quantita<=0 OR PrezzoUnitario IS NULL OR PrezzoUnitario<0)
        OR EXISTS(SELECT 1 FROM @Input GROUP BY Tipo,IdOrigine HAVING COUNT(*)>1)
        THROW 54130, ''Selezione non valida.'', 1;
    DECLARE @Impronta BINARY(32)=HASHBYTES(''SHA2_256'',CONCAT(@IdPreventivo,N''|'',@IdRigaPreventivo,N''|'',CONVERT(NVARCHAR(10),@DataOrdine,126),N''|'',@Selezione));
    DECLARE @Ordini TABLE(IdOrdineFornitore INT PRIMARY KEY, IdFornitore INT);
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @Lock INT;
        EXEC @Lock=sys.sp_getapplock @Resource=N''TEC018-Acquisti'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
        IF @Lock<0 THROW 54131, ''Altra operazione sugli ordini in corso.'', 1;
        IF EXISTS(SELECT 1 FROM dbo.OrdiniFornitoriGenerazioni WHERE Richiesta=@Richiesta)
        BEGIN
            IF NOT EXISTS(SELECT 1 FROM dbo.OrdiniFornitoriGenerazioni WHERE Richiesta=@Richiesta AND Impronta=@Impronta AND Utente=@Utente)
                THROW 54135, ''Richiesta gia utilizzata con dati diversi.'', 1;
            INSERT @Ordini SELECT j.IdOrdineFornitore,j.IdFornitore
            FROM dbo.OrdiniFornitoriGenerazioni g CROSS APPLY OPENJSON(g.OrdiniJson)
                WITH(IdOrdineFornitore INT,IdFornitore INT) j WHERE g.Richiesta=@Richiesta;
            IF EXISTS(SELECT 1 FROM @Ordini t LEFT JOIN dbo.OrdiniFornitori o ON o.IdOrdineFornitore=t.IdOrdineFornitore WHERE o.IdOrdineFornitore IS NULL)
                THROW 54135, ''Un ordine gia generato e stato eliminato. Aprire una nuova anteprima.'', 1;
        END
        ELSE
        BEGIN
            IF NOT EXISTS(SELECT 1 FROM dbo.Preventivi WITH(UPDLOCK,HOLDLOCK) WHERE IdPreventivo=@IdPreventivo)
                THROW 54132, ''Preventivo non disponibile.'', 1;
            IF @IdRigaPreventivo IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.PreventiviRighe WITH(UPDLOCK,HOLDLOCK)
                WHERE IdRigaPreventivo=@IdRigaPreventivo AND IdPreventivo=@IdPreventivo)
                THROW 54132, ''Riga non appartenente al preventivo.'', 1;
            -- Blocca le origini durante lettura e creazione. Nessun ricalcolo del preventivo.
            DECLARE @Blocco INT;
            SELECT @Blocco=p.IdRigaPreventivo FROM dbo.PreventiviRighe p WITH(UPDLOCK,HOLDLOCK) WHERE p.IdPreventivo=@IdPreventivo;
            SELECT @Blocco=c.IdRigaCompPrev FROM dbo.PreventiviRigheComponenti c WITH(UPDLOCK,HOLDLOCK)
                JOIN dbo.PreventiviRighe p ON p.IdRigaPreventivo=c.IdRigaPreventivo WHERE p.IdPreventivo=@IdPreventivo;
            SELECT @Blocco=m.IdRigaMatPrev FROM dbo.PreventiviRigheMateriali m WITH(UPDLOCK,HOLDLOCK)
                JOIN dbo.PreventiviRighe p ON p.IdRigaPreventivo=m.IdRigaPreventivo WHERE p.IdPreventivo=@IdPreventivo;
            SELECT @Blocco=l.IdRigaLavPrev FROM dbo.PreventiviRigheLavorazioni l WITH(UPDLOCK,HOLDLOCK)
                JOIN dbo.PreventiviRighe p ON p.IdRigaPreventivo=l.IdRigaPreventivo WHERE p.IdPreventivo=@IdPreventivo;
            SELECT * INTO #Origini FROM dbo.OrdiniFornitori_AcquistiPreventivo(@IdPreventivo,@IdRigaPreventivo);
            IF EXISTS(SELECT 1 FROM @Input i LEFT JOIN #Origini s ON s.Tipo=i.Tipo AND s.IdOrigine=i.IdOrigine
                WHERE s.IdOrigine IS NULL OR s.Impronta<>i.Impronta OR s.PrezzoProposto IS NULL OR s.PrezzoProposto<0)
                THROW 54132, ''Origini modificate. Riaprire anteprima.'', 1;
            IF EXISTS(SELECT 1 FROM @Input i JOIN #Origini s ON s.Tipo=i.Tipo AND s.IdOrigine=i.IdOrigine WHERE s.DaRiconciliare=1)
                THROW 54136, ''Ordini storici da riconciliare.'', 1;
            IF EXISTS(SELECT 1 FROM @Input i JOIN #Origini s ON s.Tipo=i.Tipo AND s.IdOrigine=i.IdOrigine WHERE i.Quantita>s.Residuo)
                THROW 54133, ''Quantita superiore al residuo disponibile.'', 1;
            IF EXISTS(SELECT 1 FROM @Input i WHERE NOT EXISTS(SELECT 1 FROM dbo.Fornitori f WITH(UPDLOCK,HOLDLOCK)
                WHERE f.IdFornitore=i.IdFornitore AND f.Attivo=1))
                THROW 54102, ''Fornitore non attivo.'', 1;
            DECLARE @Anno INT=YEAR(@DataOrdine),@Numero INT,@Massimo INT;
            SELECT @Numero=UltimoNumero FROM dbo.OrdiniFornitoriProgressivi WITH(UPDLOCK,HOLDLOCK) WHERE Anno=@Anno;
            SELECT @Massimo=COALESCE(MAX(NumeroOrdine),0) FROM dbo.OrdiniFornitori WITH(UPDLOCK,HOLDLOCK) WHERE Anno=@Anno;
            SET @Numero=CASE WHEN COALESCE(@Numero,0)>@Massimo THEN @Numero ELSE @Massimo END;
            DECLARE @Fornitore INT,@IdOrdine INT;
            DECLARE fornitori CURSOR LOCAL FAST_FORWARD FOR SELECT DISTINCT IdFornitore FROM @Input ORDER BY IdFornitore;
            OPEN fornitori; FETCH NEXT FROM fornitori INTO @Fornitore;
            WHILE @@FETCH_STATUS=0
            BEGIN
                SET @Numero+=1;
                INSERT dbo.OrdiniFornitori(NumeroOrdine,Anno,DataOrdine,IdFornitore,Oggetto,Stato,TotaleOrdine,
                    IdPreventivo,IdRigaPreventivo,DataCreazione,UtenteCreazione)
                VALUES(@Numero,@Anno,@DataOrdine,@Fornitore,CONCAT(N''Acquisti da preventivo '',@IdPreventivo),N''Bozza'',0,
                    @IdPreventivo,@IdRigaPreventivo,SYSDATETIME(),@Utente);
                SET @IdOrdine=CONVERT(INT,SCOPE_IDENTITY());
                INSERT @Ordini VALUES(@IdOrdine,@Fornitore);
                INSERT dbo.OrdiniFornitoriRighe(IdOrdineFornitore,RigaNr,TipoRiga,IdMateriale,IdLavorazione,
                    IdNodoDistinta,IdRigaPreventivo,IdRigaCompPrev,IdRigaMatPrev,IdRigaLavPrev,Descrizione,UM,
                    Quantita,PrezzoUnitario,TotaleRiga,QuantitaRicevuta,DataCreazione,UtenteCreazione)
                SELECT @IdOrdine,ROW_NUMBER() OVER(ORDER BY s.RigaNr,s.IdRigaCompPrev,s.Tipo,s.IdOrigine),s.Tipo,
                    CASE WHEN s.Tipo=N''Materiale'' THEN s.IdAnagrafica END,CASE WHEN s.Tipo=N''Lavorazione'' THEN s.IdAnagrafica END,
                    s.IdNodoDistinta,s.IdRigaPreventivo,s.IdRigaCompPrev,
                    CASE WHEN s.Tipo=N''Materiale'' THEN s.IdOrigine END,CASE WHEN s.Tipo=N''Lavorazione'' THEN s.IdOrigine END,
                    s.Descrizione,s.UM,i.Quantita,i.PrezzoUnitario,ROUND(i.Quantita*i.PrezzoUnitario,2),0,SYSDATETIME(),@Utente
                FROM @Input i JOIN #Origini s ON s.Tipo=i.Tipo AND s.IdOrigine=i.IdOrigine WHERE i.IdFornitore=@Fornitore;
                INSERT dbo.OrdiniFornitoriAudit(IdOrdineFornitore,IdRigaOrdineFornitore,Operazione,Utente,DataOperazione)
                    SELECT @IdOrdine,IdRigaOrdineFornitore,N''Generazione riga'',@Utente,SYSDATETIME()
                    FROM dbo.OrdiniFornitoriRighe WHERE IdOrdineFornitore=@IdOrdine;
                UPDATE dbo.OrdiniFornitori SET TotaleOrdine=(SELECT SUM(TotaleRiga) FROM dbo.OrdiniFornitoriRighe WHERE IdOrdineFornitore=@IdOrdine)
                    WHERE IdOrdineFornitore=@IdOrdine;
                INSERT dbo.OrdiniFornitoriAudit(IdOrdineFornitore,Operazione,Utente,DataOperazione)
                    VALUES(@IdOrdine,N''Generazione preventivo'',@Utente,SYSDATETIME());
                FETCH NEXT FROM fornitori INTO @Fornitore;
            END;
            CLOSE fornitori; DEALLOCATE fornitori;
            IF EXISTS(SELECT 1 FROM dbo.OrdiniFornitoriProgressivi WHERE Anno=@Anno)
                UPDATE dbo.OrdiniFornitoriProgressivi SET UltimoNumero=@Numero WHERE Anno=@Anno;
            ELSE INSERT dbo.OrdiniFornitoriProgressivi(Anno,UltimoNumero) VALUES(@Anno,@Numero);
            INSERT dbo.OrdiniFornitoriGenerazioni(Richiesta,Impronta,Utente,OrdiniJson)
                VALUES(@Richiesta,@Impronta,@Utente,(SELECT * FROM @Ordini FOR JSON PATH));
        END;
        COMMIT TRANSACTION;
        SELECT o.*,f.CodiceFornitore,f.RagioneSociale FROM @Ordini t
            JOIN dbo.OrdiniFornitori o ON o.IdOrdineFornitore=t.IdOrdineFornitore JOIN dbo.Fornitori f ON f.IdFornitore=o.IdFornitore
            ORDER BY o.NumeroOrdine;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;';
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.OrdiniFornitori_Salva
    @IdOrdine INT = NULL, @DataOrdine DATE, @IdFornitore INT,
    @Oggetto NVARCHAR(250) = NULL, @Note NVARCHAR(MAX) = NULL, @DataConsegnaPrevista DATE = NULL,
    @Utente NVARCHAR(256), @VersioneRiga BINARY(8) = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF @DataOrdine IS NULL OR @IdFornitore IS NULL OR NULLIF(LTRIM(RTRIM(@Utente)), N'''') IS NULL
        THROW 54101, ''Dati ordine incompleti.'', 1;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @LockAcquisti INT;
        EXEC @LockAcquisti=sys.sp_getapplock @Resource=N''TEC018-Acquisti'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
        IF @LockAcquisti<0 THROW 54131, ''Altra operazione sugli ordini in corso.'', 1;
        IF @IdOrdine IS NOT NULL
        BEGIN
            DECLARE @VersioneOrdine BINARY(8) = @VersioneRiga;
        IF NOT EXISTS (SELECT 1 FROM dbo.OrdiniFornitori WITH (UPDLOCK, HOLDLOCK) WHERE IdOrdineFornitore = @IdOrdine)
            THROW 54103, ''Ordine non trovato.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.OrdiniFornitori WHERE IdOrdineFornitore = @IdOrdine AND Stato = N''Bozza'')
            THROW 54105, ''Operazione consentita in Bozza.'', 1;
        IF @VersioneOrdine IS NULL OR NOT EXISTS
            (SELECT 1 FROM dbo.OrdiniFornitori WHERE IdOrdineFornitore = @IdOrdine AND VersioneRiga = @VersioneOrdine)
            THROW 54104, ''Ordine modificato da altro utente.'', 1;
            IF YEAR(@DataOrdine) <> (SELECT Anno FROM dbo.OrdiniFornitori WHERE IdOrdineFornitore = @IdOrdine)
                THROW 54112, ''La data deve appartenere all anno di numerazione.'', 1;
        END;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.Fornitori WITH (UPDLOCK, HOLDLOCK)
            WHERE IdFornitore = @IdFornitore
              AND (Attivo = 1 OR EXISTS (SELECT 1 FROM dbo.OrdiniFornitori WHERE IdOrdineFornitore = @IdOrdine AND IdFornitore = @IdFornitore))
        )
            THROW 54102, ''Fornitore non valido.'', 1;
        IF @IdOrdine IS NULL
        BEGIN
            DECLARE @Anno INT = YEAR(@DataOrdine), @Numero INT;
            SELECT @Numero = UltimoNumero FROM dbo.OrdiniFornitoriProgressivi WITH (UPDLOCK, HOLDLOCK) WHERE Anno = @Anno;
            DECLARE @Massimo INT = COALESCE((SELECT MAX(NumeroOrdine) FROM dbo.OrdiniFornitori WITH (UPDLOCK, HOLDLOCK) WHERE Anno = @Anno), 0);
            IF @Numero IS NULL
            BEGIN
                SET @Numero = @Massimo + 1;
                INSERT dbo.OrdiniFornitoriProgressivi (Anno, UltimoNumero) VALUES (@Anno, @Numero);
            END
            ELSE
            BEGIN
                SET @Numero = CASE WHEN @Numero > @Massimo THEN @Numero ELSE @Massimo END + 1;
                UPDATE dbo.OrdiniFornitoriProgressivi SET UltimoNumero = @Numero WHERE Anno = @Anno;
            END;
            INSERT dbo.OrdiniFornitori (NumeroOrdine, Anno, DataOrdine, IdFornitore, Oggetto, Stato, Note, TotaleOrdine,
                DataConsegnaPrevista, DataCreazione, UtenteCreazione)
            VALUES (@Numero, @Anno, @DataOrdine, @IdFornitore, @Oggetto, N''Bozza'', @Note, 0,
                @DataConsegnaPrevista, SYSDATETIME(), @Utente);
            SET @IdOrdine = CONVERT(INT, SCOPE_IDENTITY());
        INSERT dbo.OrdiniFornitoriAudit (IdOrdineFornitore, IdRigaOrdineFornitore, Operazione, Utente, DataOperazione)
        VALUES (@IdOrdine, NULL, N''Creazione'', @Utente, SYSDATETIME());
        END
        ELSE
        BEGIN
        UPDATE dbo.OrdiniFornitoriRighe
        SET TotaleRiga = CASE WHEN TipoRiga = N''Nota'' THEN 0 ELSE ROUND(Quantita * PrezzoUnitario, 2) END
        WHERE IdOrdineFornitore = @IdOrdine
          AND TotaleRiga <> CASE WHEN TipoRiga = N''Nota'' THEN 0 ELSE ROUND(Quantita * PrezzoUnitario, 2) END;
            UPDATE dbo.OrdiniFornitori SET DataOrdine = @DataOrdine, IdFornitore = @IdFornitore,
                Oggetto = @Oggetto, Note = @Note, DataConsegnaPrevista = @DataConsegnaPrevista,
                TotaleOrdine = (SELECT COALESCE(SUM(TotaleRiga), 0) FROM dbo.OrdiniFornitoriRighe WHERE IdOrdineFornitore = @IdOrdine),
                DataModifica = SYSDATETIME(), UtenteModifica = @Utente
            WHERE IdOrdineFornitore = @IdOrdine AND VersioneRiga = @VersioneRiga;
            IF @@ROWCOUNT <> 1 THROW 54104, ''Ordine modificato durante il salvataggio.'', 1;
        INSERT dbo.OrdiniFornitoriAudit (IdOrdineFornitore, IdRigaOrdineFornitore, Operazione, Utente, DataOperazione)
        VALUES (@IdOrdine, NULL, N''Modifica testata'', @Utente, SYSDATETIME());
        END;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
    SELECT @IdOrdine;
END;';
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.OrdiniFornitori_Righe_Salva
    @IdOrdine INT, @IdRiga INT = NULL, @RigaNr INT, @TipoRiga NVARCHAR(20),
    @IdMateriale INT = NULL, @IdLavorazione INT = NULL, @Descrizione NVARCHAR(250),
    @UM NVARCHAR(10) = NULL, @Quantita DECIMAL(18,4), @PrezzoUnitario DECIMAL(18,4),
    @DataConsegnaPrevista DATE = NULL, @Note NVARCHAR(500) = NULL, @Utente NVARCHAR(256),
    @VersioneRiga BINARY(8) = NULL, @VersioneOrdine BINARY(8)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    SET @Descrizione = NULLIF(LTRIM(RTRIM(@Descrizione)), N'''');
    IF @TipoRiga IS NULL OR @TipoRiga NOT IN (N''Materiale'', N''Lavorazione'', N''Nota'')
       OR @Descrizione IS NULL OR @RigaNr IS NULL OR @RigaNr <= 0
       OR @Quantita IS NULL OR @Quantita <= 0 OR @PrezzoUnitario IS NULL OR @PrezzoUnitario < 0
       OR NULLIF(LTRIM(RTRIM(@Utente)), N'''') IS NULL
        THROW 54101, ''Dati riga non validi.'', 1;
    IF @TipoRiga <> N''Materiale'' SET @IdMateriale = NULL;
    IF @TipoRiga <> N''Lavorazione'' SET @IdLavorazione = NULL;
    IF @TipoRiga = N''Nota'' SET @PrezzoUnitario = 0;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @LockAcquisti INT;
        EXEC @LockAcquisti=sys.sp_getapplock @Resource=N''TEC018-Acquisti'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
        IF @LockAcquisti<0 THROW 54131, ''Altra operazione sugli ordini in corso.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.OrdiniFornitori WITH (UPDLOCK, HOLDLOCK) WHERE IdOrdineFornitore = @IdOrdine)
            THROW 54103, ''Ordine non trovato.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.OrdiniFornitori WHERE IdOrdineFornitore = @IdOrdine AND Stato = N''Bozza'')
            THROW 54105, ''Operazione consentita in Bozza.'', 1;
        IF @VersioneOrdine IS NULL OR NOT EXISTS
            (SELECT 1 FROM dbo.OrdiniFornitori WHERE IdOrdineFornitore = @IdOrdine AND VersioneRiga = @VersioneOrdine)
            THROW 54104, ''Ordine modificato da altro utente.'', 1;
        IF @IdRiga IS NOT NULL
        BEGIN
        IF NOT EXISTS (SELECT 1 FROM dbo.OrdiniFornitoriRighe WITH (UPDLOCK, HOLDLOCK)
                       WHERE IdRigaOrdineFornitore = @IdRiga AND IdOrdineFornitore = @IdOrdine)
            THROW 54106, ''Riga non appartenente all ordine.'', 1;
        IF @VersioneRiga IS NULL OR NOT EXISTS
            (SELECT 1 FROM dbo.OrdiniFornitoriRighe WHERE IdRigaOrdineFornitore = @IdRiga AND VersioneRiga = @VersioneRiga)
            THROW 54107, ''Riga modificata da altro utente.'', 1;
        END;
        IF EXISTS(SELECT 1 FROM dbo.OrdiniFornitoriRighe WHERE IdRigaOrdineFornitore=@IdRiga
            AND (IdRigaMatPrev IS NOT NULL OR IdRigaLavPrev IS NOT NULL))
        BEGIN
            DECLARE @Quote INT=(SELECT IdPreventivo FROM dbo.OrdiniFornitori WHERE IdOrdineFornitore=@IdOrdine);
            IF EXISTS
            (
                SELECT 1 FROM dbo.OrdiniFornitoriRighe x
                LEFT JOIN dbo.OrdiniFornitori_AcquistiPreventivo(@Quote,NULL) s
                  ON (x.IdRigaMatPrev=s.IdOrigine AND s.Tipo=N''Materiale'') OR (x.IdRigaLavPrev=s.IdOrigine AND s.Tipo=N''Lavorazione'')
                WHERE x.IdRigaOrdineFornitore=@IdRiga AND
                (x.TipoRiga<>@TipoRiga OR ISNULL(x.IdMateriale,0)<>ISNULL(@IdMateriale,0)
                 OR ISNULL(x.IdLavorazione,0)<>ISNULL(@IdLavorazione,0) OR ISNULL(x.UM,N'''')<>ISNULL(@UM,N''''))
            ) THROW 54134, ''Conservare tipo, anagrafica e unita della riga generata.'', 1;
            IF EXISTS
            (
                SELECT 1 FROM dbo.OrdiniFornitoriRighe x
                LEFT JOIN dbo.OrdiniFornitori_AcquistiPreventivo(@Quote,NULL) s
                  ON (x.IdRigaMatPrev=s.IdOrigine AND s.Tipo=N''Materiale'') OR (x.IdRigaLavPrev=s.IdOrigine AND s.Tipo=N''Lavorazione'')
                WHERE x.IdRigaOrdineFornitore=@IdRiga AND @Quantita>x.Quantita
                  AND (s.IdOrigine IS NULL OR s.DaRiconciliare=1 OR @Quantita>s.Residuo+x.Quantita)
            ) THROW 54133, ''Quantita superiore al residuo disponibile.'', 1;
        END;
        IF @IdMateriale IS NOT NULL AND NOT EXISTS
        (
            SELECT 1 FROM dbo.Materiali WITH (UPDLOCK, HOLDLOCK) WHERE IdMateriale = @IdMateriale
            AND (Attivo = 1 OR EXISTS (SELECT 1 FROM dbo.OrdiniFornitoriRighe WHERE IdRigaOrdineFornitore = @IdRiga AND IdMateriale = @IdMateriale))
        )
            THROW 54108, ''Materiale non disponibile.'', 1;
        IF @IdLavorazione IS NOT NULL AND NOT EXISTS
        (
            SELECT 1 FROM dbo.Lavorazioni WITH (UPDLOCK, HOLDLOCK) WHERE IdLavorazione = @IdLavorazione
            AND (Attiva = 1 OR EXISTS (SELECT 1 FROM dbo.OrdiniFornitoriRighe WHERE IdRigaOrdineFornitore = @IdRiga AND IdLavorazione = @IdLavorazione))
        )
            THROW 54108, ''Lavorazione non disponibile.'', 1;
        IF EXISTS (SELECT 1 FROM dbo.OrdiniFornitoriRighe WITH (UPDLOCK, HOLDLOCK)
                   WHERE IdOrdineFornitore = @IdOrdine AND RigaNr = @RigaNr AND (@IdRiga IS NULL OR IdRigaOrdineFornitore <> @IdRiga))
            THROW 54109, ''Numero riga duplicato.'', 1;
        DECLARE @Totale DECIMAL(18,2) = ROUND(@Quantita * @PrezzoUnitario, 2);
        IF @IdRiga IS NULL
        BEGIN
            INSERT dbo.OrdiniFornitoriRighe (IdOrdineFornitore, RigaNr, TipoRiga, IdMateriale, IdLavorazione,
                Descrizione, UM, Quantita, PrezzoUnitario, TotaleRiga, QuantitaRicevuta, DataConsegnaPrevista,
                Note, DataCreazione, UtenteCreazione)
            VALUES (@IdOrdine, @RigaNr, @TipoRiga, @IdMateriale, @IdLavorazione, @Descrizione, @UM,
                @Quantita, @PrezzoUnitario, @Totale, 0, @DataConsegnaPrevista, @Note, SYSDATETIME(), @Utente);
            SET @IdRiga = CONVERT(INT, SCOPE_IDENTITY());
        INSERT dbo.OrdiniFornitoriAudit (IdOrdineFornitore, IdRigaOrdineFornitore, Operazione, Utente, DataOperazione)
        VALUES (@IdOrdine, @IdRiga, N''Creazione riga'', @Utente, SYSDATETIME());
        END
        ELSE
        BEGIN
            UPDATE dbo.OrdiniFornitoriRighe SET RigaNr = @RigaNr, TipoRiga = @TipoRiga, IdMateriale = @IdMateriale,
                IdLavorazione = @IdLavorazione, Descrizione = @Descrizione, UM = @UM, Quantita = @Quantita,
                PrezzoUnitario = @PrezzoUnitario, TotaleRiga = @Totale, DataConsegnaPrevista = @DataConsegnaPrevista,
                Note = @Note, DataModifica = SYSDATETIME(), UtenteModifica = @Utente
            WHERE IdRigaOrdineFornitore = @IdRiga AND VersioneRiga = @VersioneRiga;
            IF @@ROWCOUNT <> 1 THROW 54107, ''Riga modificata durante il salvataggio.'', 1;
        INSERT dbo.OrdiniFornitoriAudit (IdOrdineFornitore, IdRigaOrdineFornitore, Operazione, Utente, DataOperazione)
        VALUES (@IdOrdine, @IdRiga, N''Modifica riga'', @Utente, SYSDATETIME());
        END;
        UPDATE dbo.OrdiniFornitoriRighe
        SET TotaleRiga = CASE WHEN TipoRiga = N''Nota'' THEN 0 ELSE ROUND(Quantita * PrezzoUnitario, 2) END
        WHERE IdOrdineFornitore = @IdOrdine
          AND TotaleRiga <> CASE WHEN TipoRiga = N''Nota'' THEN 0 ELSE ROUND(Quantita * PrezzoUnitario, 2) END;
        UPDATE dbo.OrdiniFornitori
        SET TotaleOrdine = (SELECT COALESCE(SUM(TotaleRiga), 0) FROM dbo.OrdiniFornitoriRighe WHERE IdOrdineFornitore = @IdOrdine),
            DataModifica = SYSDATETIME(), UtenteModifica = @Utente
        WHERE IdOrdineFornitore = @IdOrdine;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
    SELECT @IdRiga;
END;';
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.OrdiniFornitori_Elimina
    @IdOrdine INT, @VersioneOrdine BINARY(8), @Utente NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF NULLIF(LTRIM(RTRIM(@Utente)), N'''') IS NULL THROW 54101, ''Utente richiesto.'', 1;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @LockAcquisti INT;
        EXEC @LockAcquisti=sys.sp_getapplock @Resource=N''TEC018-Acquisti'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
        IF @LockAcquisti<0 THROW 54131, ''Altra operazione sugli ordini in corso.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.OrdiniFornitori WITH (UPDLOCK, HOLDLOCK) WHERE IdOrdineFornitore = @IdOrdine)
            THROW 54103, ''Ordine non trovato.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.OrdiniFornitori WHERE IdOrdineFornitore = @IdOrdine AND Stato = N''Bozza'')
            THROW 54105, ''Operazione consentita in Bozza.'', 1;
        IF @VersioneOrdine IS NULL OR NOT EXISTS
            (SELECT 1 FROM dbo.OrdiniFornitori WHERE IdOrdineFornitore = @IdOrdine AND VersioneRiga = @VersioneOrdine)
            THROW 54104, ''Ordine modificato da altro utente.'', 1;
        DECLARE @Dipendenze TABLE (Tipo NVARCHAR(256), Numero BIGINT);
        INSERT @Dipendenze EXEC dbo.OrdiniFornitori_Dipendenze @IdOrdine, NULL;
        IF EXISTS (SELECT 1 FROM @Dipendenze) THROW 54110, ''Ordine con dipendenze.'', 1;
        INSERT dbo.OrdiniFornitoriAudit (IdOrdineFornitore, IdRigaOrdineFornitore, Operazione, Utente, DataOperazione)
        VALUES (@IdOrdine, NULL, N''Eliminazione ordine'', @Utente, SYSDATETIME());
        DELETE dbo.OrdiniFornitoriRighe WHERE IdOrdineFornitore = @IdOrdine;
        DELETE dbo.OrdiniFornitori WHERE IdOrdineFornitore = @IdOrdine;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;';
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.OrdiniFornitori_Righe_Elimina
    @IdOrdine INT, @IdRiga INT, @VersioneOrdine BINARY(8), @VersioneRiga BINARY(8), @Utente NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF NULLIF(LTRIM(RTRIM(@Utente)), N'''') IS NULL THROW 54101, ''Utente richiesto.'', 1;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @LockAcquisti INT;
        EXEC @LockAcquisti=sys.sp_getapplock @Resource=N''TEC018-Acquisti'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
        IF @LockAcquisti<0 THROW 54131, ''Altra operazione sugli ordini in corso.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.OrdiniFornitori WITH (UPDLOCK, HOLDLOCK) WHERE IdOrdineFornitore = @IdOrdine)
            THROW 54103, ''Ordine non trovato.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.OrdiniFornitori WHERE IdOrdineFornitore = @IdOrdine AND Stato = N''Bozza'')
            THROW 54105, ''Operazione consentita in Bozza.'', 1;
        IF @VersioneOrdine IS NULL OR NOT EXISTS
            (SELECT 1 FROM dbo.OrdiniFornitori WHERE IdOrdineFornitore = @IdOrdine AND VersioneRiga = @VersioneOrdine)
            THROW 54104, ''Ordine modificato da altro utente.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.OrdiniFornitoriRighe WITH (UPDLOCK, HOLDLOCK)
                       WHERE IdRigaOrdineFornitore = @IdRiga AND IdOrdineFornitore = @IdOrdine)
            THROW 54106, ''Riga non appartenente all ordine.'', 1;
        IF @VersioneRiga IS NULL OR NOT EXISTS
            (SELECT 1 FROM dbo.OrdiniFornitoriRighe WHERE IdRigaOrdineFornitore = @IdRiga AND VersioneRiga = @VersioneRiga)
            THROW 54107, ''Riga modificata da altro utente.'', 1;
        DECLARE @Dipendenze TABLE (Tipo NVARCHAR(256), Numero BIGINT);
        INSERT @Dipendenze EXEC dbo.OrdiniFornitori_Dipendenze @IdOrdine, @IdRiga;
        IF EXISTS (SELECT 1 FROM @Dipendenze) THROW 54110, ''Riga con dipendenze.'', 1;
        INSERT dbo.OrdiniFornitoriAudit (IdOrdineFornitore, IdRigaOrdineFornitore, Operazione, Utente, DataOperazione)
        VALUES (@IdOrdine, @IdRiga, N''Eliminazione riga'', @Utente, SYSDATETIME());
        DELETE dbo.OrdiniFornitoriRighe WHERE IdRigaOrdineFornitore = @IdRiga AND IdOrdineFornitore = @IdOrdine;
        UPDATE dbo.OrdiniFornitoriRighe
        SET TotaleRiga = CASE WHEN TipoRiga = N''Nota'' THEN 0 ELSE ROUND(Quantita * PrezzoUnitario, 2) END
        WHERE IdOrdineFornitore = @IdOrdine
          AND TotaleRiga <> CASE WHEN TipoRiga = N''Nota'' THEN 0 ELSE ROUND(Quantita * PrezzoUnitario, 2) END;
        UPDATE dbo.OrdiniFornitori
        SET TotaleOrdine = (SELECT COALESCE(SUM(TotaleRiga), 0) FROM dbo.OrdiniFornitoriRighe WHERE IdOrdineFornitore = @IdOrdine),
            DataModifica = SYSDATETIME(), UtenteModifica = @Utente
        WHERE IdOrdineFornitore = @IdOrdine;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;';
/* PAYLOAD TEC-018-GENERAZIONE END */

    INSERT dbo.VersioniSchema (Versione, CodiceIntervento, NomeScript, Descrizione, ImprontaSha256)
    VALUES (@Versione,@Codice,@Script,N'Generazione acquisti da preventivi, residui, origini puntuali e conferma transazionale.',@Impronta);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
