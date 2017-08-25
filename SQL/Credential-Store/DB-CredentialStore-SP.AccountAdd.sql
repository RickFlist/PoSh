IF ( OBJECT_ID('dbo.sp_AccountAdd') IS NOT NULL ) 
   DROP PROCEDURE dbo.sp_AccountAdd
GO

CREATE PROCEDURE dbo.sp_AccountAdd
	@AccountName		NVARCHAR(50),
	@Password			NVARCHAR(MAX),
	@ExpirationDate		DATETIME,
	@LastModified		DATETIME,
	@ModifiedBy			NVARCHAR(50),
	@Domain				NVARCHAR(50),
	@Type				NVARCHAR(50),
	@Environment		NVARCHAR(50),
	@Active				NVARCHAR(50),
	@Temporary			NVARCHAR(50),
	@Description		NVARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON

	INSERT INTO dbo.Credentials
		(
			[AccountName]		,
			[Password]			,
			[ExpirationDate]	,
			[LastModified]		,
			[ModifiedBy]		,
			[Domain]			,
			[Type]				,
			[Environment]	    ,
			[Active]			,
			[Temporary]			,
			[Description]
		)
	VALUES
		(
			@AccountName		,
			@Password			,
			@ExpirationDate		,
			GETUTCDATE()		,
			@ModifiedBy			,
			@Domain				,
			@Type				,
			@Environment		,
			@Active				,
			@Temporary			,
			@Description
		)
END