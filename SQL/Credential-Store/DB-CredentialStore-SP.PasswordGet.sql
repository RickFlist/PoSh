IF ( OBJECT_ID('dbo.sp_PasswordGet') IS NOT NULL ) 
   DROP PROCEDURE dbo.sp_PasswordGet
GO

CREATE PROCEDURE dbo.sp_PasswordGet
	@AccountName		NVARCHAR(50),
	@Environment		NVARCHAR(50)
AS
BEGIN
	SET NOCOUNT ON

	SELECT 
		Password 
	FROM 
		Credentials
	WHERE
		AccountName = @AccountName AND
		Environment = @Environment
END