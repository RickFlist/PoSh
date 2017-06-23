#region Script-Variables
# Path to function library
$Script:LibraryHost = ([Uri] ('\\max-share.osscpub.selfhost.corp.microsoft.com'))
$Script:LibraryPathSuffix = ([String] ('\library\scripts\functions\Functions.ps1'))

# SelfHost DNSSuffix
$Script:SelfHostDnsSuffix = ([String] 'osscpub.selfhost.corp.microsoft.com')
#endregion Script-Variables

## Set aliases
Set-Alias -Name 'im' -Value 'Import-Module'
Set-Alias -Name 'wh' -Value 'Write-Host'
Set-Alias -Name 'sel-sub' -Value 'Select-AzureRmSubscription'

# Test OSSCPUB DNS
$suffixList = @("redmond.corp.microsoft.com",$Script:SelfHostDnsSuffix)
$DNSGS = Get-DnsClientGlobalSetting
$DNSSuffix = $DNSGS.SuffixSearchList
if ($DNSSuffix -notcontains $suffix)
{
     # Add DNS suffix
     Write-Host "Adding DNS suffix for " -NoNewline; Write-Host "osscpub.selfhost.corp.microsoft.com" -f Cyan
     Set-DnsClientGlobalSetting -SuffixSearchList $suffixList
}
else
{
     Write-Host
     Write-Host ($Script:SelfHostDnsSuffix) -ForegroundColor Green -NoNewline
     Write-Host "added to DNS suffix search list"

     $nameResolved = Resolve-DnsName -Name $Script:LibraryHost.Host -ErrorAction SilentlyContinue

     if (-not $nameResolved)
     {
          Write-Host ('Unable to resolve hostname "{0}"!' -f $Script:LibraryHost.LocalPath.ToString()) -ForegroundColor Yellow
     }
}

# Add trusted PSGallery repositories
$psGalleryUntrusted = Get-PSRepository | Where-Object {$PSItem.Name -eq 'PSGallery' -and $PSItem.InstallationPolicy -eq 'Untrusted'}
if ($psGalleryUntrusted)
{
     Write-Host ('Setting PSGallery to "Trusted"')
     Set-PSRepository -Name $psGalleryUntrusted.Name -InstallationPolicy Trusted
}