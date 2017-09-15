$rootPath = ([System.IO.DirectoryInfo] ( 'D:\Source\Posh\Profile' ) )

Import-Module -Name ( '{0}\Profile-Current.psm1' -f $rootPath.FullName ) -Scope Global -Force

if ($env:USERDOMAIN -ne $env:COMPUTERNAME)
{	
	Import-Module -Name ( '{0}\Profile-Work.psm1' -f $rootPath.FullName ) -Scope Global -Force
}
