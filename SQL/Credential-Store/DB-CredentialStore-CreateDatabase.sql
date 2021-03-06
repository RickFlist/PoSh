-- Create database

CREATE DATABASE [CredentialStore]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'CredentialStore', FILENAME = N'D:\MSSQL-Data\MSSQL12.STD\MSSQL\DATA\CredentialStore.mdf' , SIZE = 4096KB , FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'CredentialStore_log', FILENAME = N'D:\MSSQL-Data\MSSQL12.STD\MSSQL\DATA\CredentialStore_log.ldf' , SIZE = 1024KB , FILEGROWTH = 10%)
GO
ALTER DATABASE [CredentialStore] SET COMPATIBILITY_LEVEL = 120
GO
ALTER DATABASE [CredentialStore] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [CredentialStore] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [CredentialStore] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [CredentialStore] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [CredentialStore] SET ARITHABORT OFF 
GO
ALTER DATABASE [CredentialStore] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [CredentialStore] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [CredentialStore] SET AUTO_CREATE_STATISTICS ON(INCREMENTAL = OFF)
GO
ALTER DATABASE [CredentialStore] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [CredentialStore] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [CredentialStore] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [CredentialStore] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [CredentialStore] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [CredentialStore] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [CredentialStore] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [CredentialStore] SET  DISABLE_BROKER 
GO
ALTER DATABASE [CredentialStore] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [CredentialStore] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [CredentialStore] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [CredentialStore] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [CredentialStore] SET  READ_WRITE 
GO
ALTER DATABASE [CredentialStore] SET RECOVERY FULL 
GO
ALTER DATABASE [CredentialStore] SET  MULTI_USER 
GO
ALTER DATABASE [CredentialStore] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [CredentialStore] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
ALTER DATABASE [CredentialStore] SET DELAYED_DURABILITY = DISABLED 
GO
USE [CredentialStore]
GO
IF NOT EXISTS (SELECT name FROM sys.filegroups WHERE is_default=1 AND name = N'PRIMARY') ALTER DATABASE [CredentialStore] MODIFY FILEGROUP [PRIMARY] DEFAULT
GO


-- Create Table

USE [CredentialStore]
GO

/****** Object:  Table [dbo].[Credentials]    Script Date: 12/27/2016 11:15:31 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Credentials](
	[AccountName] [nvarchar](50) NOT NULL,
	[Password] [nvarchar](max) NOT NULL,
	[ExpirationDate] [datetime] NOT NULL,
	[LastModified] [datetime] NOT NULL,
	[ModifiedBy] [nvarchar](50) NOT NULL,
	[Domain] [nvarchar](50) NOT NULL,
	[Type] [nvarchar](50) NOT NULL,
	[Temporary] [nvarchar] (50) NOT NULL,
	[Environment] [nvarchar](50) NOT NULL,
	[Active] [nvarchar](50) NOT NULL,
	[Description] [nvarchar](max) NULL,
	[SecurityScope] [nvarchar](50) NOT NULL,
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

ALTER TABLE Credentials
	ADD CONSTRAINT AK_AccountName UNIQUE(AccountName,Environment)
GO

-- DROP TABLE Credentials