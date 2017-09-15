#region Script-Variables
# Library paths
$Script:LibraryHost = ( [Uri] ( '\\max-share.osscpub.selfhost.corp.microsoft.com' ) )
$Script:LibraryPathSuffix = ( [String] ( 'library\scripts\functions' ) )
$Script:LibraryAbsolutePath = ( [System.IO.DirectoryInfo] ( '{0}\{1}' -f $Script:LibraryHost.LocalPath,$Script:LibraryPathSuffix ) )
$Script:CpModulesFolder = ( [System.IO.DirectoryInfo] ( 'D:\Source\MAX-CPub-Lab\Modules' ) )

# SelfHost DNSSuffix
$Script:SelfHostDnsSuffix = ( [String] ( 'osscpub.selfhost.corp.microsoft.com' ) )

# Local source repository
$Script:RepoRootFolder = ( [System.IO.FileInfo] ( 'D:\Source' ) )

# Is Corporate Connected
$Script:CorpConnected =( [Bool] ( $false ) )
#endregion Script-Variables

#region Functions
function Import-MaxModules
{
     [CmdletBinding()]
     [OutputType()]

     param ()

     process
     {
          # Import existing MAX functions
          if ( ($Script:CorpConnected) -and ( Test-Path -LiteralPath $Script:LibraryAbsolutePath.FullName -PathType Container )  )
          {
               Get-ChildItem -LiteralPath $maxFunctionsFolder -File -Filter 'MAX*.psm1' | `
                    ForEach-Object {
                         Import-Module -Name $PSItem.FullName -Global -Force
                    }
          }

          # Import CP modules
          if ( Test-Path -LiteralPath $Script:CpModulesFolder.FullName -PathType Container )
          {
               Get-ChildItem -LiteralPath $Script:CpModulesFolder.FullName -Directory -Filter 'CP-*' | `
                    ForEach-Object {
                         Import-Module -Name $PSItem.FullName -Global -Force
                    }
          }
     }
}

function Register-RmProfileC, bu
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
          try
          {
               Import-Module AzureRM.profile -Force -Global

               $profPath = [System.IO.FileInfo] (Join-Path -Path $env:APPDATA -ChildPath ('AzureProfiles\AzProfile-{0}.json' -f $env:USERNAME))
               if (-not (Test-Path -LiteralPath $profPath.Directory.FullName -PathType Container))
               {
                    $profPath.Directory.Create() | Out-Null
               }

               $profPath.Refresh()

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
                    $profPath.Refresh()
                    if (-not $profPath.Exists)
                    {
                         $rmProfile = Login-AzureRmAccount -SubscriptionName $DefaultSubscriptionName
                         Save-AzureRmContext -Profile $rmProfile -Path $profPath -Force
                    }
               }

               $azContext = Import-AzureRmContext -Path $profPath
               Microsoft.PowerShell.Utility\Write-Host ('Authenticated to "{0}" as "{1}" account. Current subscription is "{2}"' -f $azContext.Context.Environment.Name,$azContext.Context.Account.Id,$azContext.Context.Subscription.Name)
          }
          catch
          {
               throw ($PSItem)
          }


     }
}

function Save-RmProfile
{
     [CmdletBinding()]
     [OutputType()]

     param
     (
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          # PSProfile objecting containing cachable authentication infomration
          [Microsoft.Azure.Commands.Profile.Models.PSAzureProfile]
          $AzureProfile
     )

     process
     {
          if ( -not $PSBoundParameters.ContainsKey('AzureProfile') )
          {
               $AzureProfile = ( Login-AzureRmAccount )
          }

          $profPath = [System.IO.FileInfo] (Join-Path -Path $env:APPDATA -ChildPath ('AzureProfiles\AzProfile-{0}.json' -f $env:USERNAME))
          if (-not (Test-Path -LiteralPath $profPath.Directory.FullName -PathType Container))
          {
               $profPath.Directory.Create() | Out-Null
          }

          try
          {
               $null = Save-AzureRmContext -Profile $AzureProfile -Path $profPath -Force
          }
          catch
          {
               throw ($PSItem)
          }

          Write-Host ('Azure profile for "{0}" saved to "{1}"' -f $AzureProfile.Context.Account.Id,$profPath.FullName  )
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
     $Script:CorpConnected = $true
}

# Add trusted PSGallery repositories
$psGalleryUntrusted = Get-PSRepository | Where-Object {$PSItem.Name -eq 'PSGallery' -and $PSItem.InstallationPolicy -eq 'Untrusted'}
if ($psGalleryUntrusted)
{
     Write-Host ('Setting PSGallery to "Trusted"')
     Set-PSRepository -Name $psGalleryUntrusted.Name -InstallationPolicy Trusted
}
#endregion Execution