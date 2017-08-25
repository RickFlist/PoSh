IF ( OBJECT_ID('dbo.sp_RemoveEnvironment') IS NOT NULL ) 
   DROP PROCEDURE dbo.sp_RemoveEnvironment
GO

CREATE PROCEDURE dbo.sp_RemoveEnvironment
	@Environment		NVARCHAR(50)

AS
BEGIN
	DELETE FROM Credentials
		WHERE Environment = @Environment
END