/*
    TEC-005 - Autenticazione applicativa
    Prerequisiti: tabelle UtentiApplicazione, UtentiRuoli,
    RuoliApplicazione e vista vw_MenuApplicazionePermessi.
    Lo script non modifica dati esistenti ed e ripetibile.
*/

CREATE OR ALTER PROCEDURE dbo.Sicurezza_UtenteAccesso_Get
    @Username NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        u.IdUtente,
        u.Username,
        u.NomeCompleto,
        u.PasswordHash,
        u.Attivo
    FROM dbo.UtentiApplicazione AS u
    WHERE u.Username = @Username
      AND u.Attivo = 1;

    SELECT DISTINCT r.CodiceRuolo
    FROM dbo.UtentiApplicazione AS u
    INNER JOIN dbo.UtentiRuoli AS ur ON ur.IdUtente = u.IdUtente
    INNER JOIN dbo.RuoliApplicazione AS r ON r.IdRuolo = ur.IdRuolo
    WHERE u.Username = @Username
      AND u.Attivo = 1
      AND r.Attivo = 1
    ORDER BY r.CodiceRuolo;

    SELECT DISTINCT p.NomeMaschera
    FROM dbo.vw_MenuApplicazionePermessi AS p
    WHERE p.Username = @Username
    ORDER BY p.NomeMaschera;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Sicurezza_AdminPassword_Inizializza
    @Username NVARCHAR(50),
    @PasswordHash NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    UPDATE u
    SET u.PasswordHash = @PasswordHash
    FROM dbo.UtentiApplicazione AS u
    WHERE u.Username = @Username
      AND u.Attivo = 1
      AND NULLIF(LTRIM(RTRIM(u.PasswordHash)), N'') IS NULL
      AND EXISTS
      (
          SELECT 1
          FROM dbo.UtentiRuoli AS ur
          INNER JOIN dbo.RuoliApplicazione AS r ON r.IdRuolo = ur.IdRuolo
          WHERE ur.IdUtente = u.IdUtente
            AND r.CodiceRuolo = N'ADMIN'
            AND r.Attivo = 1
      );

    SELECT @@ROWCOUNT;
END;
GO
