-- Creates a database master key for the "CredentialStore" database.   
-- The key is encrypted using the password supplied
USE "CredentialStore";  
GO  
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'P@ssw0rd!';  
GO  
