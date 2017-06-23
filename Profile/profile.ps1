<# - Used if one would like to use OneDrive as their "source control"
function Get-OneDriveUserFolder
{
    process
    {
        $osVersion = ([System.Version]((Get-CimInstance Win32_OperatingSystem).Version))

        [System.IO.DirectoryInfo] $oneDriveUserFolder = $null

        if ($osVersion.Major -eq 10)
        {
            $regPath = 'hkcu:\Software\Microsoft\OneDrive\'
            $regKey = 'UserFolder'

            if (Test-Path -Path $regPath)
            {
                $oneDriveUserFolder = (Get-ItemProperty -Path "hkcu:\Software\Microsoft\OneDrive\" -Name $regKey).UserFolder
            }
        }
        else
        {
            $regPath = 'hkcu:\Software\Microsoft\Windows\CurrentVersion\SkyDrive\'
            $regKey = 'UserFolder'

            $oneDriveUserFolder = (Get-ItemProperty -Path $regPath -Name $regKey).UserFolder
        }

        Write-Output ($oneDriveUserFolder)
    }
}

# Relative path from root of OneDrive folder
$childPath = 'Profile-Current.ps1'
$Global:SyncedProfilePath = ([System.IO.FileInfo] (Join-Path -Path (Get-OneDriveUserFolder) -ChildPath $childPath -Resolve))

. $($Global:SyncedProfilePath.FullName)
#>

. "D:\Source\PoSh\Profile\Profile-Current.ps1"
. "D:\Source\PoSh\Profile\MaxLabs.ps1"