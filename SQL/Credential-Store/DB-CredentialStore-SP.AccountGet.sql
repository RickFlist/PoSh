IF ( OBJECT_ID('dbo.sp_AccountGet') IS NOT NULL ) 
   DROP PROCEDURE dbo.sp_AccountGet
GO

CREATE PROCEDURE dbo.sp_AccountGet
	@AccountName		NVARCHAR(50)
AS
BEGIN
	SET NOCOUNT ON

	SELECT * 
		FROM Credentials
		WHERE AccountName = @AccountName
END