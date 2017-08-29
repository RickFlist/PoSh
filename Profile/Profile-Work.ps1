#region Script-Variables
# Path to function library
$Script:LibraryHost = ([Uri] ('\\max-share.osscpub.selfhost.corp.microsoft.com'))
$Script:LibraryPathSuffix = ([String] ('\library\scripts\functions\Functions.ps1'))

# SelfHost DNSSuffix
$Script:SelfHostDnsSuffix = ([String] 'osscpub.selfhost.corp.microsoft.com')

# Local source repository
$Script:RepoRootFolder = ( [System.IO.FileInfo] ( 'D:\Source' ) )
#endregion Script-Variables

#region Functions
function Import-MaxModules
{
     [CmdletBinding()]
     [OutputType()]

     param
     (
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          # Path to MAX modules
          [System.IO.DirectoryInfo]
          $LiteralPath = ('\\max-share\library\scripts\functions')
     )

     process
     {
          Get-ChildItem -LiteralPath $LiteralPath -File -Filter 'MAX*.psm1' | ForEach-Object {
               Import-Module -Name $PSItem.FullName -Global -Force
          }
     }
}

function Register-RmProfile
{
     [CmdletBinding()]
     param
     (
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          [ValidateSet('Office CPub Production 1','MAX CPub Lab - Test 1','MAX CPub Lab - DevTest','MAX CPub Lab - Dedicated Corpnet','Office CPub ContentQA','MAX CPub Lab - Dedicated Corpnet 2','Office CPub Production 2')]
          # Subscription to deploy to
          [String]
          $DefaultSubscriptionName = 'Office CPub ContentQA'
          ,
          [Parameter()]
          [Switch]
          # For re-authentication of Azure account
          $Force
     )

     process
     {
          Import-Module AzureRM.profile -Force -Global

          $profPath = [System.IO.FileInfo] (Join-Path -Path $env:APPDATA -ChildPath ('AzureProfiles\AzProfile-{0}.json' -f $env:USERNAME))
          if (-not (Test-Path -LiteralPath $profPath.Directory.FullName -PathType Container))
          {
               $profPath.Directory.Create() | Out-Null
          }

          if ($Force.IsPresent)
          {
               $rmProfile = Login-AzureRmAccount -SubscriptionName $DefaultSubscriptionName

               $profPath.Refresh()
               if ($profPath.Exists)
               {
                    Remove-Item -LiteralPath $profPath.FullName -Force
               }

               Save-AzureRmContext -Profile $rmProfile -Path $profPath -Force
          }
          else
          {
               if (-not $profPath.Exists)
               {
                    $rmProfile = Login-AzureRmAccount -SubscriptionName $DefaultSubscriptionName
                    Save-AzureRmContext -Profile $rmProfile -Path $profPath -Force
               }
          }

          $azContext = Import-AzureRmContext -Path $profPath
          Microsoft.PowerShell.Utility\Write-Host ('Authenticated to "{0}" as "{1}" account. Current subscription is "{2}"' -f $azContext.Context.Environment.Name,$azContext.Context.Account.Id,$azContext.Context.Subscription.Name)

     }
}

function Set-DnsSuffixList
{
     [CmdletBinding()]
     [OutputType()]

     param
     (
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          # Suffixes to Append
          [String[]]
          $DnsSuffix = @('osscpub.selfhost.corp.microsoft.com')
     )

     process
     {
          $DnsGlobalSetting = Get-DnsClientGlobalSetting
          if ( ( $DnsGlobalSetting.SuffixSearchList ) -and ( $DnsGlobalSetting.SuffixSearchList -notcontains $Script:SelfHostDnsSuffix ) )
          {
               Write-Host ('Current DNS suffix search list does not contain "{0}". Adding' -f $Script:SelfHostDnsSuffix)

               Set-DnsClientGlobalSetting -SuffixSearchList = ( ( [String[]] ( $DnsGlobalSetting.SuffixSearchList + $Script:SelfHostDnsSuffix ) ) )
               Write-Host ('Updated DNS suffix search list: {0}' -f ( (Get-DnsClientGlobalSetting).SuffixSearchList -join ', ' ) )
          }
     }
}
#endregion Functions

#region Execution
if ( Test-Path -LiteralPath $Script:RepoRootFolder.FullName -PathType Container )
{
     Set-Location -LiteralPath $Script:RepoRootFolder.FullName
}

Import-MaxModules
Set-DnsSuffixList
Register-RmProfile

## Set aliases
Set-Alias -Name 'im' -Value 'Import-Module'
Set-Alias -Name 'wh' -Value 'Write-Host'
Set-Alias -Name 'sel-sub' -Value 'Select-AzureRmSubscription'

Write-Host ('Verifying corporate connectivity. This can take awhile if not connected') -ForegroundColor Gray
$resolutionResults = ( Test-DnsNameResolutionByConnection -DnsName $Script:LibraryHost.Host -Quiet | Where-Object { $PSItem.NIC -match 'VPN' } )

if ( ($resolutionResults | Where-Object { $PSItem.NameResolutionResult.CanResolveDns -eq $true }).Count -eq 0 )
{
     Write-Host ( 'Unable to resolve DNS "{0}". Verify corporate connectivity' -f $Script:LibraryHost.Host )
}
else
{
     $resolutionResults | `
          ForEach-Object {
               Write-Host ("{0} - DNS: {1} - ResolvedIp(s): {2}" -f `
                    $PSItem.NIC,`
                    $PSItem.DnsServerIP,`
                    (
                         (
                              (
                                   $PSItem.NameResolutionResult.ResolvedIpAddresses.GetEnumerator() | `
                                        ForEach-Object {
                                             ( 'IP: {0}   Type: {1}' -f $PSItem.Key,$PSItem.Value  )
                                        } ) `
                                        -Join ', ' | `
                                        Sort-Object | `
                                        Select-Object -Unique
                         ) -join ', '
                    )
               ) -ForegroundColor DarkGray
          }
     Write-Host ('Valid corporate connection detected')
}

# Add trusted PSGallery repositories
$psGalleryUntrusted = Get-PSRepository | Where-Object {$PSItem.Name -eq 'PSGallery' -and $PSItem.InstallationPolicy -eq 'Untrusted'}
if ($psGalleryUntrusted)
{
     Write-Host ('Setting PSGallery to "Trusted"')
     Set-PSRepository -Name $psGalleryUntrusted.Name -InstallationPolicy Trusted
}
#endregion Execution