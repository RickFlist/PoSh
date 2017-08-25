-- Creates a backup of the "CredentialStore" master key. Because this master key is not encrypted by the service master key, a password must be specified when it is opened.  
USE "CredentialStore";   
GO  
OPEN MASTER KEY DECRYPTION BY PASSWORD = 'P@ssw0rd!';   

BACKUP MASTER KEY TO FILE = 'Path to File'   
    ENCRYPTION BY PASSWORD = 'P@ssw0rd!';
GO