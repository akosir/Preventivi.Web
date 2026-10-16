/*
    TEC-005 - Account SQL a privilegi minimi per Preventivi.Web

    Esecuzione esclusivamente in modalita SQLCMD da parte di un amministratore.
    Specificare una password non versionata:
      sqlcmd ... -v PreventiviWebPassword="..." DatabaseName="PreventiviProduzione"

    Lo script crea il login solo se assente e non ruota password esistenti.
*/

:setvar PreventiviWebPassword "CAMBIARE-PRIMA-DELL-ESECUZIONE"
:setvar DatabaseName "PreventiviProduzione"

USE [master];
GO

DECLARE @Password NVARCHAR(128) = N'$(PreventiviWebPassword)';

IF @Password = N'CAMBIARE-PRIMA-DELL-ESECUZIONE'
BEGIN
    THROW 51000, 'Specificare PreventiviWebPassword tramite variabile SQLCMD.', 1;
END;

IF NOT EXISTS
(
    SELECT 1
    FROM sys.server_principals
    WHERE name = N'PreventiviWeb'
)
BEGIN
    DECLARE @CreateLogin NVARCHAR(MAX) =
        N'CREATE LOGIN [PreventiviWeb] WITH PASSWORD = '
        + QUOTENAME(@Password, '''')
        + N', CHECK_POLICY = ON, CHECK_EXPIRATION = OFF;';

    EXEC sys.sp_executesql @CreateLogin;
END;
GO

USE [$(DatabaseName)];
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_principals
    WHERE name = N'PreventiviWeb'
)
BEGIN
    CREATE USER [PreventiviWeb] FOR LOGIN [PreventiviWeb];
END;
GO

GRANT CONNECT TO [PreventiviWeb];
GRANT EXECUTE ON SCHEMA::dbo TO [PreventiviWeb];
GO
