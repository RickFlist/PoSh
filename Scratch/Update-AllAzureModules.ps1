#requires -Modules PowerShellGet
#Requires -Version 5.0
#Requires -RunAsAdministrator

[CmdletBinding()]
[OutputType([OutputType])]

param
(
    # Install Azure Classic modules
    [Switch]
    $InstallClassic    
)

process
{
    #region Script-Variables
    [String]           $Script:azClassiceModuleName = ( 'Azure')
    [String]           $Script:azRmModuleName = ( 'AzureRM' )
    [String]           $Script:startTimeStamp = ( Get-Date -Format 'yyyyMMdd-HHmmss' )
    [String]           $Script:timeStampFormat = ( 'MM/dd HH:mm:ss.ffff' )
    [String]           $Script:fileStampFormat = ( 'yyyyMMdd-HHmmss' )
    [String[]]         $Script:IgnoredModules = ( 'AzureAutomationAuthoringToolkit', 'AzureInformationProtection' )
    [IO.DirectoryInfo] $Script:OutputFolder = ( '{0}\Desktop\AzModsUpdateLog' -f $Home )
    [IO.FileInfo]      $Script:BeforeFile = ( '{0}\AzureModules-Before-{1}-{2}' -f $Script:OutputFolder.FullName, ( Get-Date -Format $Script:fileStampFormat ), $env:USERNAME )
    [IO.FileInfo]      $Script:AfterFile = ( '{0}\AzureModules-After-{1}-{2}' -f $Script:OutputFolder.FullName, ( Get-Date -Format $Script:fileStampFormat ), $env:USERNAME )
    #endregion Script-Variables

    #region DevTesting-Stuff
    Set-StrictMode -Version Latest
    #endregion DevTesting-Stuff

    #region Environment-Configuraiton
    $glbTimer = ( New-Object -TypeName System.Diagnostics.Stopwatch )
    $opTimer = ( New-Object -TypeName System.Diagnostics.Stopwatch )
    $stepTimer = ( New-Object -TypeName System.Diagnostics.Stopwatch )

    $glbTimer.Restart()
    $opTimer.Restart()
    #endregion Environment-Configuraiton

    #region Execution

    #region Check-For-Other-PowerShell-Processes
    $otherProcs = @( Get-Process | Where-Object -FilterScript { ($PSItem.Name -match 'powershell') -and ( $PSItem.Id -ne $PID ) } )
    if ( $otherProcs )
    {
        Write-Host ('{0} | Elpsd: {1:000.00} seconds | Op: {2:000.00} seconds | Found {3} other PowerShell processes. Some updates may not complete correctly!' -f ( Get-Date -Format $Script:timeStampFormat ), $glbTimer.Elapsed.TotalSeconds, $opTimer.Elapsed.TotalSeconds, $otherProcs.Count )
    }
    #endregion Check-For-Other-PowerShell-Processes

    Write-Host

    #region Check-PSGet-Modules
    $opTimer.Restart()
    Write-Host ('{0} | Elpsd: {1:000.00} seconds | Op: {2:000.00} seconds | Looking for Azure modules installed with PowerShellGet ... ' -f ( Get-Date -Format $Script:timeStampFormat ), $glbTimer.Elapsed.TotalSeconds, $opTimer.Elapsed.TotalSeconds )
    $psGetMods = @( Get-InstalledModule | Where-Object { $Script:IgnoredModules -notcontains $PSItem.Name } | Where-Object { $PSItem.Name.StartsWith( $Script:azClassiceModuleName ) } )
    if ( $psGetMods )
    {
        Write-Host ('{0} | Elpsd: {1:000.00} seconds | Op: {2:000.00} seconds | Found {3} Azure/AzureRM modules installed with PowerShellGet. Uninstalling ' -f ( Get-Date -Format $Script:timeStampFormat ), $glbTimer.Elapsed.TotalSeconds, $opTimer.Elapsed.TotalSeconds, $psGetMods.Count )

        foreach ( $mod in $psGetMods )
        {
            $stepTimer.Restart()
            Write-Host ('{0} | Elpsd: {1:000.00} seconds | Op: {2:000.00} seconds | Uninstalling module {3}, all versions ... ' -f `
                ( Get-Date -Format $Script:timeStampFormat ), $glbTimer.Elapsed.TotalSeconds, $opTimer.Elapsed.TotalSeconds, $mod.Name ) -NoNewline
            $null = ( Uninstall-Module -Name $mod.Name -AllVersions -Force )
            Write-Host ( 'Completed ({0:0.00} seconds)' -f $stepTimer.Elapsed.TotalSeconds ) -ForegroundColor Green
        }

        Write-Host ('{0} | Elpsd: {1:000.00} seconds | Op: {2:000.00} seconds | All PowerShellGet Modules uninstalled in {3:0.00} seconds ... ' -f `
            ( Get-Date -Format $Script:timeStampFormat ), $glbTimer.Elapsed.TotalSeconds, $opTimer.Elapsed.TotalSeconds, $opTimer.Elapsed.TotalSeconds ) 
    }
    else 
    {
        Write-Host ('{0} | Elpsd: {1:000.00} seconds | Op: {2:000.00} seconds | Found Azure/AzureRM 0 modules installed with PowerShellGet ... ' -f ( Get-Date -Format $Script:timeStampFormat ), $glbTimer.Elapsed.TotalSeconds, $opTimer.Elapsed.TotalSeconds )
    }
    #endregion Check-PSGet-Modules

    Write-Host

    #region Check-ManuallyInstalled-Modules
    $opTimer.Restart()
    Write-Host ('{0} | Elpsd: {1:000.00} seconds | Op: {2:000.00} seconds | Looking for Azure modules installed manually ... ' -f ( Get-Date -Format $Script:timeStampFormat ), $glbTimer.Elapsed.TotalSeconds, $opTimer.Elapsed.TotalSeconds )
    $psManualMods = @( Get-Module -ListAvailable | Where-Object { $Script:IgnoredModules -notcontains $PSItem.Name } | Where-Object { $PSItem.Name.StartsWith( $Script:azClassiceModuleName ) } )
    if ( $psManualMods )
    {
        Write-Host ('{0} | Elpsd: {1:000.00} seconds | Op: {2:000.00} seconds | Found {3} manually installed modules ... ' -f `
            ( Get-Date -Format $Script:timeStampFormat ), $glbTimer.Elapsed.TotalSeconds, $opTimer.Elapsed.TotalSeconds, $psManualMods.Count )
    
        foreach ( $manMod in $psManualMods )
        {
            $stepTimer.Restart()
            Write-Host ('{0} | Elpsd: {1:000.00} seconds | Op: {2:000.00} seconds | Removing module {3} v{4} ... ' -f `
                ( Get-Date -Format $Script:timeStampFormat ), $glbTimer.Elapsed.TotalSeconds, $opTimer.Elapsed.TotalSeconds, $psManualMods.Count, $manMod.Name, $manMod.Version.ToString() ) -NoNewline
            $null = ( Remove-Item -LiteralPath $manMod.ModuleBase -Recurse -Force )
            Write-Host ( 'Completed ({0:0.00} seconds)' -f $stepTimer.Elapsed.TotalSeconds ) -ForegroundColor Green
        }

        Write-Host ('{0} | Elpsd: {1:000.00} seconds | Op: {2:000.00} seconds | Removed all manually instaleld module sin {3:0.00} seconds' -f `
            ( Get-Date -Format $Script:timeStampFormat ), $glbTimer.Elapsed.TotalSeconds, $opTimer.Elapsed.TotalSeconds, $opTimer.Elapsed.TotalSeconds ) 
    }
    else
    {
        Write-Host ('{0} | Elpsd: {1:000.00} seconds | Op: {2:000.00} seconds | Found 0 manually installed modules ... ' -f `
            ( Get-Date -Format $Script:timeStampFormat ), $glbTimer.Elapsed.TotalSeconds, $opTimer.Elapsed.TotalSeconds )
    }
    #endregion Check-ManuallyInstalled-Modules

    #region Install-Azure-Modules
    if ( $InstallClassic.IsPresent )
    {
        Write-Host
        $opTimer.Restart()
        Write-Host ('{0} | Elpsd: {1:000.00} seconds | Op: {2:000.00} seconds | Installing Azure Classic Module(s) ... ' -f `
            ( Get-Date -Format $Script:timeStampFormat ), $glbTimer.Elapsed.TotalSeconds, $opTimer.Elapsed.TotalSeconds )
        $null = Install-Module -Name $Script:azClassiceModuleName -Scope AllUsers -AllowClobber -Force
        Write-Host ('{0} | Elpsd: {1:000.00} seconds | Op: {2:000.00} seconds | Azure Classic module(s) installed in {3:0.00} seconds ... ' -f `
            ( Get-Date -Format $Script:timeStampFormat ), $glbTimer.Elapsed.TotalSeconds, $opTimer.Elapsed.TotalSeconds, $opTimer.Elapsed.TotalSeconds )
    }
    #endregion Install-Azure-Modules

    Write-Host

    #region Install-AzureRm-Modules
    $opTimer.Restart()
    Write-Host ('{0} | Elpsd: {1:000.00} seconds | Op: {2:000.00} seconds | Installing AzureRM Module(s) ... ' -f `
        ( Get-Date -Format $Script:timeStampFormat ), $glbTimer.Elapsed.TotalSeconds, $opTimer.Elapsed.TotalSeconds )
    $null = Install-Module -Name $Script:azRmModuleName -Scope AllUsers -AllowClobber -Force
    Write-Host ('{0} | Elpsd: {1:000.00} seconds | Op: {2:000.00} seconds | AzureRM module(s) installed in {3:0.00} seconds ... ' -f `
        ( Get-Date -Format $Script:timeStampFormat ), $glbTimer.Elapsed.TotalSeconds, $opTimer.Elapsed.TotalSeconds, $opTimer.Elapsed.TotalSeconds )
    #endregion Install-AzureRm-Modules

    #endregion Execution
}