IF ( OBJECT_ID('dbo.sp_AccountSetInactive') IS NOT NULL ) 
   DROP PROCEDURE dbo.sp_AccountSetInactive
GO

CREATE PROCEDURE dbo.sp_AccountSetInactive
	@AccountName		NVARCHAR(50)
AS
BEGIN
	SET NOCOUNT ON

	UPDATE Credentials
		SET Active = N'N',
		LastModified = GETUTCDATE()
	WHERE
		AccountName = @AccountName
			
END
