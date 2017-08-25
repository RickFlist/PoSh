-- Restores the database master key of the "MDP-CredentialStore" database.
USE "MDP-CredentialStore";
GO
RESTORE MASTER KEY
    FROM FILE = 'Path to File'
    DECRYPTION BY PASSWORD = 'P@ssw0rd!'
    ENCRYPTION BY PASSWORD = 'P@ssw0rd!';
GO