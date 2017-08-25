USE master;
GO
CREATE LOGIN [DOMAIN\username] FROM WINDOWS WITH DEFAULT_DATABASE=[CredentialStore]
GO
USE [CredentialStore];
GO
CREATE USER [DOMAIN\username] FROM LOGIN [DOMAIN\username];
GO
EXEC sp_addrolemember 'db_owner', 'DOMAIN\username';
GO

-- DROP LOGIN [DOMAIN\username]