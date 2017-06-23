#Requires -Version 5.1
#Requires -RunAsAdministrator
Set-StrictMode -Version Latest

function Test-Cmdlet
{
     [CmdletBinding(
          ConfirmImpact = 'High',
          SupportsShouldProcess = $true
     )]
     [OutputType([String])]

     param
     (
          [Parameter(Mandatory = $true)]
          [ValidateNotNullOrEmpty()]
          # Test Mandatory Parameter
          [Object]
          $ObjectOne
          ,
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          # Test Non-Mandatory Parameter
          [Object]
          $ObjectTwo = ('ParamTwo')
     )

     process
     {
          calc.exe
          # $ConfirmPreference = 'Medium'
          Get-Process -ProcessName calc* | Stop-Process -Force
     }
}