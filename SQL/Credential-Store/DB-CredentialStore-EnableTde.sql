-- The master key must be in the master database.
USE Master;
GO

-- Create the master key.
CREATE MASTER KEY ENCRYPTION
	BY PASSWORD='P@ssw0rd!';
GO

-- To verify key creation execute:
-- SELECT * FROM sys.symmetric_keys

-- Create a certificate.
CREATE CERTIFICATE CredStoreCertificate
	WITH SUBJECT='Credential.Store.Certificate';
GO

-- Switch to the database to enable TDE.
USE [CredentialStore]
GO

-- Associate the certificate to MyDatabase.
CREATE DATABASE ENCRYPTION KEY
	WITH ALGORITHM = AES_256
	ENCRYPTION BY SERVER CERTIFICATE CredStoreCertificate;
GO

ALTER DATABASE [CredentialStore]
	SET ENCRYPTION ON;
GO

-- Monitoring TDE
USE master
GO

SELECT * FROM sys.certificates

-- encryption_state = 3 is encrypted
SELECT * FROM sys.dm_database_encryption_keys
  WHERE encryption_state = 3;