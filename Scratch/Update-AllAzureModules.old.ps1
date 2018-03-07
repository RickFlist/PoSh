#requires -Modules PowerShellGet
#Requires -Version 5.0
#Requires -RunAsAdministrator

#region Script-Variables
[String]           $Script:azClassiceModuleName = ( 'Azure')
[String]           $Script:azRmModuleName = ( 'AzureRM' )
[String]           $Script:startTimeStamp = ( Get-Date -Format 'yyyyMMdd-HHmmss' )
[String]           $Script:timeStampFormat = ( 'MM/dd HH:mm:ss.ffff' )
[String[]]         $Script:IgnoredModules = ( 'AzureAutomationAuthoringToolkit','AzureInformationProtection' )
[IO.DirectoryInfo] $Script:OutputFolder = ( '{0}\Desktop\AzModsUpdateLog' -f $Home )
[IO.FileInfo]      $Script:BeforeFile = ( '{0}\AzureModules-Before-{1}-{2}' -f $Script:OutputFolder.FullName,( Get-Date -Format $Script:startTimeStamp ),$env:USERNAME )
[IO.FileInfo]      $Script:AfterFile = ( '{0}\AzureModules-After-{1}-{2}' -f $Script:OutputFolder.FullName,( Get-Date -Format $Script:startTimeStamp ),$env:USERNAME )
#endregion Script-Variables

#region DevTesting-Stuff
Set-StrictMode -Version Latest
#endregion DevTesting-Stuff

#region Environment-Configuraiton
$glbTimer  = ( New-Object -TypeName System.Diagnostics.Stopwatch )
$opTimer   = ( New-Object -TypeName System.Diagnostics.Stopwatch )
$stepTimer = ( New-Object -TypeName System.Diagnostics.Stopwatch )

$glbTimer.Restart()
$opTimer.Restart()
#endregion Environment-Configuraiton

#region Check-For-Other-PowerShell-Processes
$otherProcs = @( Get-Process | Where-Object -FilterScript { ($PSItem.Name -match 'powershell') -and ( $PSItem.Id -ne $PID ) } )
if ( $otherProcs )
{
    Write-Host ('{0} | Elpsd: {1:000.00} seconds | Op: {2:000.00} seconds | Found {3} other PowerShell processes. Some updates may not complete correctly!' -f ( Get-Date -Format $Script:timeStampFormat ),$glbTimer.Elapsed.TotalSeconds,$opTimer.Elapsed.TotalSeconds,$otherProcs.Count )
}
#endregion Check-For-Other-PowerShell-Processes

#region Execution

#region Remove-PackageManger-Modules
$opTimer.Restart()
Write-Host ('{0} | Elpsd: {1:000.00} seconds | Op: {2:000.00} seconds | Looking for manually installed modules {3} and {4}' -f ( Get-Date -Format $Script:timeStampFormat ),$glbTimer.Elapsed.TotalSeconds,$opTimer.Elapsed.TotalSeconds,$Script:azClassiceModuleName,$Script:azRmModuleName ) -ForegroundColor Yellow
$installedModules = ( Get-InstalledModule | Where-Object { $PSItem.Name -match $Script:azClassiceModuleName } )
#endregion Remove-PackageManger-Modules

#region Remove-Non-PackageMaanager-Modules
$opTimer.Restart(); 
Write-Host ('{0} | Elpsd: {1:000.00} seconds | Op: {2:000.00} seconds | Looking for root modules {3} and {4}' -f ( Get-Date -Format $Script:timeStampFormat ),$glbTimer.Elapsed.TotalSeconds,$opTimer.Elapsed.TotalSeconds,$Script:azClassiceModuleName,$Script:azRmModuleName ) -ForegroundColor Yellow
try
{
    # Remove classic module, if it is installed
    $azCsscModObj = ( Get-Module -Name $Script:azClassiceModuleName -ListAvailable )
    if ( $azCsscModObj )
    {
        $null = ( Uninstall-Module -Name $Script:azClassiceModuleName -AllVersions -Force )
        Write-Host ('{0} | Elpsd: {1:000.00} seconds | Op: {2:000.00} seconds | Module {3} has been uninstalled' -f ( Get-Date -Format $Script:timeStampFormat ),$glbTimer.TotalSeconds,$opTimer.Elapsed.TotalSeconds,$Script:azClassiceModuleName ) -ForegroundColor Green
    }

    $azRmModObj = ( Get-Module -Name $Script:azRmModuleName -ListAvailable )
    if ( $azRmModObj )
    {
        $null = ( Uninstall-Module -Name $Script:azRmModuleName )
        Write-Host ('{0} | Elpsd: {1:000.00} seconds | Op: {2:000.00} seconds | Module {3} is installed' -f ( Get-Date -Format $Script:timeStampFormat ),$glbTimer.TotalSeconds,$opTimer.Elapsed.TotalSeconds,$Script:azClassiceModuleName ) -ForegroundColor Gray
    }

    # Remove ARM module, if installed
    $azRmModObj = ( Get-Module -Name $Script:azRmModuleName -ListAvailable )
    if ( $azRmModObj )
    {
        $null = ( Uninstall-Module -Name $Script:azRmModuleName -AllVersions -Force )
        Write-Host ('{0} | Elpsd: {1:000.00} seconds | Op: {2:000.00} seconds | Module {3} has been uninstalled' -f ( Get-Date -Format $Script:timeStampFormat ),$glbTimer.TotalSeconds,$opTimer.Elapsed.TotalSeconds,$Script:azRmModuleName ) -ForegroundColor Green
    }
    else
    {
        Write-Host ('{0} | Elpsd: {1:000.00} seconds | Op: {2:000.00} seconds | Module {3} is installed' -f ( Get-Date -Format $Script:timeStampFormat ),$glbTimer.TotalSeconds,$opTimer.Elapsed.TotalSeconds,$Script:azRmModuleName )
    }
}
catch
{
    throw ( $PSItem )
}
#endregion Remove-Non-PackageMaanager-Modules

#region Uninstall-PoweShellGet-Modules
$opTimer.Restart()
$modCompanyName = ( 'azure-sdk' )
$modPrefix = ( 'Azure' )
Write-Host ('{0} | Elpsd: {1:000.00} seconds | Op: {2:000.00} seconds | Gathering all modules installed via PSModule relating to Azure' -f ( Get-Date -Format $Script:timeStampFormat ),$glbTimer.TotalSeconds,$opTimer.Elapsed.TotalSeconds ) -ForegroundColor Yellow
$allPsGetMods = ( Get-InstalledModule | Where-Object -FilterScript { ( $PSItem.CompanyName -eq $modCompanyName ) -and ( $PSItem.Name.StartsWith( $modPrefix ) ) } )
Write-Host ('{0} | Elpsd: {1:000.00} seconds | Op: {2:000.00} seconds | Found {3} modules installed via PowerShellGet' -f ( Get-Date -Format $Script:timeStampFormat ),$glbTimer.TotalSeconds,$opTimer.Elapsed.TotalSeconds,$allPsGetMods.Count ) -ForegroundColor Gray

$opTimer.Restart()
$modsUninstalled = ( [Int] 0 )
$failedUninstalles = ( [Int] 0 )
Write-Host ('{0} | Elpsd: {1:000.00} seconds | Op: {2:000.00} seconds | Removing Azure modules installed via PowerShellGet' -f ( Get-Date -Format $Script:timeStampFormat ),$glbTimer.TotalSeconds,$opTimer.Elapsed.TotalSeconds )
foreach ( $mod in $allPsGetMods )
{
    $stepTimer.Restart()
    Write-Host ('{0} | Elpsd: {1:000.00} seconds | Op: {2:000.00} seconds | Uninstalling module {3} v{4} from "{5}", published {6} and installed {7}' -f `
        ( Get-Date -Format $Script:timeStampFormat ),$glbTimer.TotalSeconds,$opTimer.Elapsed.TotalSeconds,`
            $mod.Name,$mod.Version.ToString(),$mod.PublishedDate.ToString( 'MM/dd/yy HH:mm:ss' ),$mod.InstalledDate.ToString( 'MM/dd/yyyy HH:mm:ss' )
    ) -NoNewline -ForegroundColor Yellow

    try
    {
        $null = ( Uninstall-Module -Name $mod.Name -Force )
        $modsUninstalled++
        Write-Host ( ' ... Completed uninstall of module {0} out of {1} in {3:00:00} seconds' -f $modsUninstalled,$allPsGetMods.Count,$stepTimer.Elapsed.TotalSeconds ) -ForegroundColor Green
    }
    catch
    {
        $failedUninstalles++ 
        Write-Host ( ' ... Error uninstalling module {0},v{1} in {2:00.00} seconds' -f $mod.Name,$mod.Version.ToString(),$stepTimer.Elapsed.TotalSeconds ) -ForegroundColor Red -BackgroundColor White
        Write-Host
        Write-Error -ErrorRecord $PSItem
        Write-Host
        continue
    }
}

Write-Host ('{0} | Elpsd: {1:000.00} seconds | Op: {2:000.00} seconds | Out of {3} total modules, {4} were uninstalled and {5} encountered errors' -f `
    ( Get-Date -Format $Script:timeStampFormat ),$glbTimer.TotalSeconds,$opTimer.Elapsed.TotalSeconds,$allPsGetMods,$modsUninstalled,$failedUninstalles )
#endregion Uninstall-PoweShellGet-Modules

#region Look-For-And-Uninstall-Other-LeftOvers
$opTimer.Restart()
Write-Host ('{0} | Elpsd: {1:000.00} seconds | Op: {2:000.00} seconds | Removing any modules installed via other methods' -f ( Get-Date -Format $Script:timeStampFormat ),$glbTimer.TotalSeconds,$opTimer.Elapsed.TotalSeconds )
$allLegModes = ( Get-Module -ListAvailable | Where-Object -FilterScript { ( $PSItem.Name.StartsWith( 'Azure' ) ) -and ( $Script:IgnoredModules -notcontains $PSItem.Name ) } )

if ( $allLegModes )
{
    Write-Host ('{0} | Elpsd: {1:000.00} seconds | Op: {2:000.00} seconds | Found {3} legacy Azure modules' -f ( Get-Date -Format $Script:timeStampFormat ),$glbTimer.TotalSeconds,$opTimer.Elapsed.TotalSeconds,$allLegModes.Count )
    foreach ( $legMod in $allLegModes )
    {
        $stepTimer.Restart()
        Write-Host ('{0} | Elpsd: {1:000.00} seconds | Op: {2:000.00} seconds | Uninstalling module {3} v{4} from "{5}"' -f ( Get-Date -Format $Script:timeStampFormat ),$glbTimer.TotalSeconds,$opTimer.Elapsed.TotalSeconds,$legMod.Name,$legMod.Version,$legMod.ModuleBase ) -NoNewline
        
        try
        {
            $null = ( Remove-Item -LiteralPath $legMod.ModuleBase -Recurse -Force )
            Write-Host ( ' ... Completed' ) -ForegroundColor Green
        }
        catch
        {
            Write-Host ( ' ... Failed' ) -ForegroundColor Red
            throw ( $PSItem )
        }
    }
}
else
{
    Write-Host ('{0} | Elpsd: {1:000.00} seconds | Op: {2:000.00} seconds | No legacy modules found' -f ( Get-Date -Format $Script:timeStampFormat ),$glbTimer.TotalSeconds,$opTimer.Elapsed.TotalSeconds )
}
#endregion Look-For-And-Uninstall-Other-LeftOvers

#endregion Execution