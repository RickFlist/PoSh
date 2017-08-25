IF ( OBJECT_ID('dbo.sp_PasswordUpdate') IS NOT NULL ) 
   DROP PROCEDURE dbo.sp_PasswordUpdate
GO

CREATE PROCEDURE dbo.sp_PasswordUpdate
	@AccountName		NVARCHAR(50),
	@Environment		NVARCHAR(50),
	@Password			NVARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON

	UPDATE Credentials 
	SET 
		Password = @Password,
		LastModified = GETUTCDATE()
	WHERE 
		AccountName = @AccountName AND
		Environment = @Environment
END