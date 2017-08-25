-- Creates a backup of the service master key.  
-- Because this master key is not encrypted by the service master key, a password must be specified when it is opened.  
USE master;  
GO  
BACKUP SERVICE MASTER KEY TO FILE = 'Path To File'   
    ENCRYPTION BY PASSWORD = 'P@ssw0rd!';  
GO