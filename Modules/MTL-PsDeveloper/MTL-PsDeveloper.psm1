#region Script-Variables
#region For:New-VersionNumber(Get-Date -Format 'yyyy')
[int]$script:NvnMajor = 1
[int]$script:NvnMinor = 0
[int]$script:NvnBuild = (Get-Date -Format 'yyMMdd')
[int]$script:NvnRevision = 0
#endregion For:New-VersionNumber
#endregion Script-Variables

#region Public-Functions
#region For-Testing
function New-PsExampleCallstack
{
    PROCESS
    {
        return (Enter-FrameOne)
    }
}

function New-PsExampleException
{
    [CmdletBinding()]
    Param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Object] $Exception
    )

    PROCESS
    {
        if($Exception)
        {
            Enter-ErrorFrameOne -Exception $Exception
        }
        else
        {
            Enter-ErrorFrameOne
        }
    }
}
#endregion For-Testing

#region Manifests
function Get-PSModuleFunctionList
{
     [CmdletBinding()]
     [OutputType([OutputType])]

     param
     (
          [Parameter(Mandatory = $true)]
          [ValidateNotNullOrEmpty()]
          # List of modules to search
          [System.IO.FileInfo]
          $LiteralPath
          ,
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          # Starts looking for function names after this line
          [String]
          $StartLineSearchString = ( '#region Public-Functions' )
          ,
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          # The file is searched until this line is found
          [String]
          $EndLineSearchString = ( '#endregion Public-Functions' )
          ,
          [Parameter()]
          # Returns results as [String] instead of [String[]]
          [Switch]
          $ReturnAsString
     )

     process
     {
          Write-Debug ('Test')
          if ( -not ( Test-Path -LiteralPath $LiteralPath.FullName -PathType Leaf ) )
          {
               throw ( New-Object -TypeName System.IO.FileNotFoundException -ArgumentList ( 'Cannot find file {0}' -f $LiteralPath.FullName ) )
          }

          $fileContents = ( Get-Content -LiteralPath $LiteralPath.Fullname )

          Write-Debug ( 'File {0} contains {1} lines' -f $LiteralPath.FullName,$fileContents.Count )

          # Find the line numbers containing StartLineSearchString and EndLineSearchString
          $firstLineNumber = ( [Int] 0 )
          $lastLineNumber = ( [Int] 0 )
          $currentLineNumber = ( [int] 0 )

          :FindLineNumbers foreach ( $line in $fileContents )
          {
               if ( $line.Trim() -eq $StartLineSearchString )
               {
                    Write-Debug ( 'Start search string found on line {0}' -f $currentLineNumber )
                    $firstLineNumber = $currentLineNumber
               }
               elseif ($line.Trim() -eq $EndLineSearchString )
               {
                    Write-Debug ( 'End search string found on line {0}' -f $currentLineNumber )
                    $lastLineNumber = $currentLineNumber
               }

               $currentLineNumber++

               if ( ( $firstLineNumber -ne 0 ) -and ( $lastLineNumber -ne 0 ) )
               {
                    Write-Debug ( 'First and last line numbers are {0} and {1} respectively' -f $firstLineNumber,$lastLineNumber )
                    break :FindLineNumbers
               }
          }

          # Search file for function names
          $functionNames = ( New-Object -TypeName System.Collections.ArrayList )
          $currentLineNumber = ( [Int] 0 )

          $filteredFileContents = ( $fileContents[$firstLineNumber..$lastLineNumber] )
          foreach ( $line in $filteredFileContents )
          {
               if ( $line.ToUpper().Trim().StartsWith( 'FUNCTION' ) )
               {
                    Write-Debug ('Line {0} contains function "{0}"' -f $line)

                    $line = ( $line -replace 'function' ).Trim()
                    $line = ( $line -replace '{' ).Trim()

                    Write-Debug ( 'Extracted text: {0}' -f $line )

                    $null = $functionNames.Add( $line )
               }
               $currentLineNumber++
          }

          Write-Debug ( 'Extracted function Names: {0}' -f ( $functionNames | Out-String ).Trim() )

          Write-Output ( ([String[]] $functionNames ) )
     }
}

function Get-PSModuleFileList
{
     [CmdletBinding()]
     [OutputType([OutputType])]

     param
     (
          [ValidateNotNullOrEmpty()]
          # Path to search for files
          [System.IO.DirectoryInfo]
          $LiteralPath = ( $PWD.Path )
          ,
          # Files to include. Defaults to *.*
          [String[]]
          $IncludeFilter = ( '*.*' )
          ,
          # Files to exclude. Defaults to none
          [String[]]
          $ExcludeFilter
     )

     process
     {
          [System.IO.FileInfo[]]$FileList = @()
          $FileList = @(Get-ChildItem -Path ('{0}\*' -f $LiteralPath.FullName) -File -Include $IncludeFilter -Exclude $ExcludeFilter | `
              Sort-Object -Property Name | `
              Sort-Object -Property Extension -Descending
          )

          Write-Debug ('Search Path: {0}' -f $LiteralPath.FullName)
          Write-Debug ('Include Filter: {0}' -f ( $IncludeFilter -join ', ' ) )
          Write-Debug ('Exclude Filter: {0}' -f ( $ExcludeFilter -join ', ' ) )
          Write-Debug ('Files Found: {0}' -f ( $FileList.Count -join ', ' ) )

          if ( $FileList ) { $FileList | ForEach-Object { $PSItem.FullName } }
     }
}

function New-PSModuleManifest
{
     [CmdletBinding()]
     [OutputType()]

     param
     (
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          # Specifies the directory in which to generate the module manifest. The manifest file is named after the RootModule, if specified, otherwise it uses the directory name.
          [Alias('Path')]
          [System.IO.FileInfo]
          $LiteralPath = ( $PWD.Path )
          ,
          [ValidateNotNullOrEmpty()]
          # Cmdlets to export
          [String[]]
          $CmdletsToExport = @()
          ,
          [ValidateNotNullOrEmpty()]
          # Name of the company that authored the module
          [String]
          $CompanyName = ( 'N/A' )
          ,
          [ValidateNotNullOrEmpty()]
          [ValidateSet('Desktop','Core')]
          # Specifies the compatible PSEditions of the module. For information about PSEdition. See https://docs.microsoft.com/en-us/powershell/gallery/psget/module/modulewithpseditionsupport for more information
          [String[]]
          $CompatiblePSEditions = @()
          ,
          [ValidateNotNullOrEmpty()]
          # Description
          [String]
          $DefaultCommandPrefix = ( 'CP' )
          ,
          [ValidateNotNullOrEmpty()]
          # Description of the module
          [String]
          $Description
          ,
          [ValidateNotNullOrEmpty()]
          # List of files included in the module
          [String[]]
          $FileList = @()
          ,
          [ValidateNotNullOrEmpty()]
          # List of functions to export
          [String[]]
          $FunctionsToExport = @()
          ,
          [ValidateNotNullOrEmpty()]
          # GUID to use as a unique identifier
          [GUID]
          $GUID = ( [GUID]::NewGuid().Guid )
          ,
          [ValidateNotNullOrEmpty()]
          # List of all included modules
          [Object[]]
          $ModuleList = @()
          ,
          [ValidateNotNullOrEmpty()]
          # Version of the module. If not specified, it will look for an existing manifest and pull the version from that. If there is no existing module, then 1.0 is the default value.  Versions should be read as MajorVersion.MinorVersion.BuildDate.BuildNumber
          [Version]
          $ModuleVersion = ( '1.0.{0}.1' -f (Get-Date -Format 'yyyyMMdd') )
          ,
          [ValidateNotNullOrEmpty()]
          # Specifies script modules (.psm1) and binary modules (.dll) that are imported into the module's session state
          [Object[]]
          $NestedModules = @()
          ,
          [ValidateNotNullOrEmpty()]
          # Specifies the name of the Windows PowerShell host program that the module requires.
          [String]
          $PowerShellHostName
          ,
          [ValidateNotNullOrEmpty()]
          # Specifies the name of the Windows PowerShell host program that the module requires
          [Version]
          $PowerShellHostVersion
          ,
          [ValidateNotNullOrEmpty()]
          # Specifies the assembly (.dll) files that the module requires. Enter the assembly file names. Windows PowerShell loads the specified assemblies before updating types or formats, importing nested modules, or importing the module file that is specified in the value of the RootModule key.
          [Object[]]
          $RequiredAssemblies = @()
          ,
          [ValidateNotNullOrEmpty()]
          # Specifies modules that must be in the global session state
          [Object[]]
          $RequiredModules = @()
          ,
          [ValidateNotNullOrEmpty()]
          # Specifies the primary or root file of the module. Enter the file name of a script (.ps1), a script module (.psm1), a module manifest (.psd1), an assembly (.dll), a cmdlet definition XML file (.cdxml), or a workflow (.xaml). When the module is [String]
          [String]
          $RootModule
          ,
          [ValidateNotNullOrEmpty()]
          # Specifies script (.ps1) files that run in the caller's session state when the module is imported. You can use these scripts to prepare an environment, just as you might use a logon script.
          [String[]]
          $ScriptsToProcess = @()
          ,
          [ValidateNotNullOrEmpty()]
          # Description
          [String]
          $Author = ( $env:USERNAME )
          ,
          # Increments the major version number
          [Switch]
          $IncrementMajorVersion
          ,
          # Increments the minor version number
          [Switch]
          $IncrementMinorVersion
          ,
          # Output contents of manifest to the pipeline
          [Switch]
          $PassThru
     )

     process
     {
          # Create some stopwatches to track execution times
          $glblTimer = ( New-Object -TypeName System.Diagnostics.StopWatch )
          $opTimer = ( New-Object -TypeName System.Diagnostics.StopWatch )

          $glblTimer.Restart()
          $opTimer.Restart()

          # Create the parameter splat
          $mmParamSplat = @{}

          $mmParamSplat.Add( 'Copyright',( '(c) {0}' -f [DateTime]::Now.Year ) )
          $mmParamSplat.Add( 'Author',$Author )
          $mmParamSplat.Add( 'CompanyName',$CompanyName )
          $mmParamSplat.Add( 'DefaultCommandPrefix',$DefaultCommandPrefix )

          if ( $PSBoundParameters.ContainsKey( 'PassThru' ) ) { $mmParamSplat.Add( 'PassThru',$PassThru.IsPresent ) }

          #region Generate-Manifest-Filename
          $mnfstBaseName = ( $LiteralPath.Name )
          if ( $PSBoundParameters.ContainsKey( 'RootModule' ) )
          {
               $mnfstBaseName = $RootModule
          }

          $mnfstFilename = ( '{0}.psd1' -f $mnfstBaseName )

          $mnfstOutputPath = ( [System.IO.FileInfo] ( Join-Path -Path $LiteralPath.FullName -ChildPath $mnfstFilename ) )

          $mmParamSplat.Add( 'Path',$mnfstOutputPath.FullName )
          #endregion Generate-Manifest-Filename

          # Generate the updated version number
          #region Generate-Version-Number
          $existingVersion = $null
          if ( Test-Path -LiteralPath $mnfstOutputPath.FullName -PathType Leaf )
          {
               Write-Debug ( '[Total {0:0.00}s]|[Op {1:0.00}s] : Existing module manifest found that matches the target name "{2}"' -f $glblTimer.Elapsed.TotalSeconds,$opTimer.Elapsed.TotalSeconds,$mnfstOutputPath.FullName )
               $existingVersion = ( Test-ModuleManifest -Path $mnfstOutputPath.FullName -Verbose:$false ).Version
               Write-Verbose ( '[Total {0:0.00}s]|[Op {1:0.00}s] : Existing module version number: {2}' -f $glblTimer.Elapsed.TotalSeconds,$opTimer.Elapsed.TotalSeconds,$existingVersion.ToString() )
          }
          else
          {
               Write-Verbose ( 'No existing manfiest exists. Cannot retrieve current version number')
          }

          # Update an existing version number
          $opTimer.Restart()
          $generatedModuleVersion = $null
          if ( $existingVersion )
          {
               # Increment the major version if requested
               if ( $IncrementMajorVersion.IsPresent )
               {
                    $generatedModuleVersion = ( [Version] ( '{0}.{1}.{2}.{3}' -f ($existingVersion.Major + 1),$existingVersion.Minor,(Get-Date -Format 'yyyyMMdd'),($existingVersion.Revision + 1) ) )
               }

               # Increment the minor version if requested
               if ( $IncrementMinorVersion.IsPresent )
               {
                    if ( $generatedModuleVersion )
                    {
                         $generatedModuleVersion = ( [Version] ( '{0}.{1}.{2}.{3}' -f $generatedModuleVersion.Major,($generatedModuleVersion.Minor + 1),(Get-Date -Format 'yyyyMMdd'),($generatedModuleVersion.Revision + 1) ) )
                    }
                    else
                    {
                         $generatedModuleVersion = ( [Version] ( '{0}.{1}.{2}.{3}' -f $existingVersion.Major,($existingVersion.Minor + 1), (Get-Date -Format 'yyyyMMdd'),($existingVersion.Revision + 1) ) )
                    }
               }

               # Make sure the Build and Revision are set correctly
               if ($generatedModuleVersion )
               {
                    $generatedModuleVersion = ( [Version] ( '{0}.{1}.{2}.{3}' -f $generatedModuleVersion.Major,$generatedModuleVersion.Minor,(Get-Date -Format 'yyyyMMdd'),($generatedModuleVersion.Revision + 1) ) )
               }
               else
               {
                    $generatedModuleVersion = ( [Version] ( '{0}.{1}.{2}.{3}' -f $existingVersion.Major,$existingVersion.Minor,(Get-Date -Format 'yyyyMMdd'),($existingVersion.Revision + 1) ) )
               }

          }
          else # just use the ModuleVersion parameter
          {
               $generatedModuleVersion = $ModuleVersion
          }
          $opTimer.Stop()

          if ( -not $generatedModuleVersion )
          {
               throw ( New-Object -TypeName System.OperationCanceledException -ArgumentList ( 'Failed generating the updated version number for this manfest. This is probably a bug. Cannot continue' ) )
          }

          Write-Verbose ( '[Total {0:0.00}s]|[Op {1:0.00}s] : Generated version is {2}' -f $glblTimer.Elapsed.TotalSeconds,$opTimer.Elapsed.TotalSeconds,$generatedModuleVersion.ToString() )

          # Add value to parameter $mmParamSplat
          $mmParamSplat.Add( 'ModuleVersion',$generatedModuleVersion )
          #endregion Generate-Version-Number

          # Gets the list of file(s) for the FileList, ModuleList, and NestedModules parameters
          #region Get-FileList
          $opTimer.Restart()
          $allFiles = ( [String[]] @() )
          if ( -not $PSBoundParameters.ContainsKey( 'FileList' ) )
          {
               $Include = ( [String[]] ( '*.*' ) )
               $Exclude = ( [String[]] ( @() ) )

               $allFiles = @( Get-PSModuleFileList -LiteralPath $LiteralPath.FullName -IncludeFilter $Include -ExcludeFilter $Exclude )
          }
          elseif ( $FileList.Count -gt 0 )
          {
               $allFiles = $FileList
          }
          if ( $allFiles.Count -gt 0 ) { $mmParamSplat.Add( 'FileList',$allFiles ) }
          Write-Verbose ( '[Total {0:0.00}s]|[Op {1:0.00}s] : {2} file(s) will be listed in FileList' -f $glblTimer.Elapsed.TotalSeconds,$opTimer.Elapsed.TotalSeconds,$allFiles.Count )

          $opTimer.Restart()
          $allModules = ( [Object[]] @() )
          if ( -not $PSBoundParameters.ContainsKey( 'ModuleList' ) )
          {
               $Include = ( [String[]] ( '*.psm1' ) )
               $Exclude = ( [String[]] ( @('*.tests.*') ) )

               $allModules = @( Get-PSModuleFileList -LiteralPath $LiteralPath.FullName -IncludeFilter $Include -ExcludeFilter $Exclude )
          }
          elseif ( $ModuleList.Count -gt 0 )
          {
               $allModules = $ModuleList
          }
          if ( $allModules.Count -gt 0 ) { $mmParamSplat.Add( 'ModuleList',$allModules ) }
          Write-Verbose ( '[Total {0:0.00}s]|[Op {1:0.00}s] : {2} file(s) will be listed in ModuleList' -f $glblTimer.Elapsed.TotalSeconds,$opTimer.Elapsed.TotalSeconds,$allModules.Count)

          $opTimer.Restart()
          $allNestedModules = ( [Object[]] @() )
          if ( -not $PSBoundParameters.ContainsKey( 'NestedModules' ) )
          {
               $Include = ( [String[]] ( '*.psm1','*.ps1' ) )
               $Exclude = ( [String[]] ( @('*.tests.*') ) )

               $allNestedModules = @( Get-PSModuleFileList -LiteralPath $LiteralPath.FullName -IncludeFilter $Include -ExcludeFilter $Exclude )
          }
          elseif ( $NestedModules.Count -gt 0 )
          {
               $allNestedModules = $NestedModules
          }
          if ( $allNestedModules.Count -gt 0 ) { $mmParamSplat.Add( 'NestedModules',$allNestedModules ) }
          $opTimer.Stop()
          Write-Verbose ( '[Total {0:0.00}s]|[Op {1:0.00}s] : {2} file(s) will be listed in NestedModules' -f $glblTimer.Elapsed.TotalSeconds,$opTimer.Elapsed.TotalSeconds,$allNestedModules.Count)

          Write-Verbose ( '[Total {0:0.00}s]|[Op {1:0.00}s] : Completed generating file lists' -f $glblTimer.Elapsed.TotalSeconds,$opTimer.Elapsed.TotalSeconds )
          #endregion Get-FileList

          #region Get-FunctionList
          # Get list of functions to export for FunctionsToExport parameter
          if ( -not $PSBoundParameters.ContainsKey( 'FunctionsToExport' ) )
          {
               $opTimer.Restart()
               $fullFunctionList = ( New-Object -TypeName System.Collections.ArrayList )

               foreach ( $file in $allNestedModules )
               {
                    $modFunctionList = @()
                    $modFunctionList = @( Get-PSModuleFunctionList -LiteralPath $file )

                    Write-Verbose ( '[Total {0:0.00}s]|[Op {1:0.00}s] : Found {2} functions in file "{3}"' -f $glblTimer.Elapsed.TotalSeconds,$opTimer.Elapsed.TotalSeconds,$modFunctionList.Count,$file )

                    if ( $modFunctionList )
                    {
                         $null = $fullFunctionList.AddRange( $modFunctionList )
                    }
               }
               $opTimer.Stop()
               Write-Verbose ( '[Total {0:0.00}s]|[Op {1:0.00}s] : Found {2} functions in {3} file(s)' -f $glblTimer.Elapsed.TotalSeconds,$opTimer.Elapsed.TotalSeconds,$fullFunctionList.Count,$allNestedModules.Count )
          }
          #endregion Get-FunctionList

          #region Output-Module-Configuration
          Microsoft.PowerShell.Utility\Write-Host
          Write-Host ( 'The module manifest will be built using the following parameters:' )
          foreach ( $keypair in $mmParamSplat.GetEnumerator() )
          {
               Write-Host ( "`t{0,-30} : {1}" -f $keypair.Key,( $keypair.Value -join ', ' ) )
          }
          Microsoft.PowerShell.Utility\Write-Host
          #endregion Output-Module-Configuration

          New-ModuleManifest @mmParamSplat
     }
}

<#
function Get-PsModuleFileList
{
    [CmdletBinding()]

    Param
    (

        [Parameter(ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        # Path to retrieve files from
        [System.IO.DirectoryInfo] $Path = ($PWD.ProviderPath)
        ,
        [Parameter()]
        # Files to include in file list
        [String[]] $Include = @()
        ,
        [Parameter()]
        # Files to exclude from file list
        [String[]] $Exclude = (@())

    )

    PROCESS
    {
         Write-Host ('{0} {1} - Start {0}' -f $Script:HeaderCharacters, $MyInvocation.MyCommand) -ForegroundColor Green
          Write-Host

        Write-Debug ("Parameter Values:")
        Write-Debug ("Path:       {0}" -f ($Path.Fullname))

        if($Include.Count -gt 0)
        {
            Write-Debug ("Include:    {0}" -f ($Include))
        }
        else
        {
            Write-Debug ("Include:    {0}" -f ("NULL"))
        }

        if($Exclude.Count -gt 0)
        {
            Write-Debug ("Exclude:    {0}" -f ($Exclude))
        }
        else
        {
            Write-Debug ("Exclude:    {0}" -f ("NULL"))
        }
        Write-Debug ('')

        [System.IO.FileInfo[]]$FileList = @()
        $FileList = (Get-ChildItem -Path ("$Path\*") -File -Include $Include -Exclude $Exclude | `
            Sort Name | `
            Sort Extension -Descending
        )

        Write-Debug ("Files found: {0}" -f ($FileList.Count))

        Write-Output ($FileList)

        Write-Debug ("PROCESS:Leaving:  [Get-ModuleFileLiist]")
    }
}

function New-PsModuleManifest
{
    [CmdletBinding()]

    Param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        # Path and name of manifest file
        [System.IO.FileInfo]
        $ManifestPath = ("{0}.psd1" -f (Split-Path $Pwd.ProviderPath -Leaf))
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        # List of all files packaged with this module
        [System.IO.FileInfo[]] $FileList = ([System.IO.FileInfo[]]@())
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        # List of all modules packaged with this module
        [System.IO.FileInfo[]] $ModuleList = ([System.IO.FileInfo[]]@())
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
        [System.IO.FileInfo[]] $NestedModules = ([System.IO.FileInfo[]]@())
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        # Author of this module
        [String] $Author = ('theosomos@gmail.com')
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        # Required CLR version
        [System.Version] $CLRVersion
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        # Prefix for all commmands included in module
        [String] $CommandPrefix
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        # Name of company that wrote the module
        [String] $CompanyName = ('toddle Enterprises')
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        # Copyright information
        [String] $Copyright = ("(c) $([DateTime]::Now.Year). All rights reserved.")
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        # Description of the functionality provided by this module
        [String] $Description = ("An undescribed module")
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        # List of Cmdlets to export
        [String[]] $FunctionsToExport = ([String[]] @())
        <#,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        # Minimum version of the Windows PowerShell host required by this module
        [System.Version] $PowerShellHostVersion = ("5.0")
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        # Minimum version of the Windows PowerShell engine required by this module
        [System.Version] $PowerShellVersion = ("5.0")
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        # Private data to pass to the module specified in RootModule/ModuleToProcess
        [Object]
        $PrivateData
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        # Modules that must be imported into the global environment prior to importing this module
        [String[]] $RequiredModules
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        # Version number of this module
        [System.Version] $ModuleVersion
        ,
        [Parameter()]
        # Increment the major verison number
        [Switch] $IncrementMajor
        ,
        [Parameter()]
        # Increment the minor verison number
        [Switch] $IncrementMinor

    )

    BEGIN
    {
        # Create Indent Strings
        $StdIndent      = (' ' * 4)
        $OneTabIndent   = ($StdIndent * 1)
        $TwoTabIndent   = ($StdIndent * 2)
        $ThreeTabIndent = ($StdIndent * 3)
        $FourTabIndent  = ($StdIndent * 4)
        $FiveTabIndent  = ($StdIndent * 5)
    }

    PROCESS
    {
        Write-Host
        Write-Host ("Creating Module Manifest {0} ... " -f $Path) -ForegroundColor Green

        #region Generate-Version-Number
        $updatedVer = [System.Version]::new()
        if ($IncrementMajor.IsPresent)
        {
            $updatedVer = New-VersionNumber -IncrementMajor
        }
        elseif ($IncrementMinor.IsPresent)
        {
            $updatedVer = New-VersionNumber -IncrementMinor
        }

        if ($PSBoundParameters.ContainsKey('ModuleVersion'))
        {
            $updatedVer = New-VersionNumber -Version $ModuleVersion -IncrementMajor -IncrementMinor
        }
        else
        {
            if(Test-Path -LiteralPath $Path)
            {
                #region Write-Debug
                Write-Debug ("Existing version found, generating incremental version number")
                #endregion Write-Debug

                $currentVer = ((Test-ModuleManifest -Path $Path).Version)

                $updatedVer = New-VersionNumber -Version $currentVer -IncrementMajor -IncrementMinor

                #region Write-Debug
                Write-Debug ("Generated Version: {0}" -f ($updatedVer.ToString()))
                #endregion Write-Debug
            }
        }
        #endregion Generate-Version-Number

        #region Show-Parameter-Values
        Write-Debug ('')
        [int]$Alignment = 25

        Write-Debug ("Bound Parameters:")

        $PSBoundParameters.GetEnumerator() | `
            foreach {
                Write-Debug ("Key:{0,$Alignment}Value:{1,$Alignment}" -f ($_.Key),($_.Value))
            }
        Write-Debug ('')
        #endregion Show-Parameter-Values

        #region Get-File-Lists
        Write-Debug ("-FileList count:        {0}" -f ($FileList.Count))
        Write-Debug ("-ModuleList count:      {0}" -f ($ModuleList.Count))
        Write-Debug ("-NestedModules count:   {0}" -f ($NestedModules.Count))

        # If -FileList, -ModuleList, or -NestedModules are null, get own file list
        if(($FileList.Count -le 0) -or ($ModuleList.Count -le 0) -or ($NestedModules.Count -le 0))
        {
            [String[]]$Include = (("*.*").Split(','))
            [String[]]$Exclude = (@())

            #region Get-File-List
            if($FileList.Count -le 0)
            {
                $FileList = (Get-PsModuleFileList -Path ($PWD.ProviderPath) -Include $Include -Exclude $Exclude)
                Write-Debug ("-FileList Count:    {0}" -f ($FileList.Count))
            }
            #endregion Get-File-List

            #region Get-Module-List
            if($ModuleList.Count -le 0)
            {
                [String[]]$Include = (("*.psm1").Split(','))
                $ModuleList = (Get-PsModuleFileList -Path ($PWD.ProviderPath) -Include $Include -Exclude $Exclude)
                Write-Debug ("-ModuleList Count:  {0}" -f ($ModuleList.Count))
            }
            #endregion Get-Module-List

            #region Get-NestedModules-List
            if($NestedModules.Count -le 0)
            {
                [String[]]$Include = (("*.psm1,*.ps1").Split(','))
                $NestedModules = (Get-PsModuleFileList -Path ($PWD.ProviderPath) -Include $Include -Exclude $Exclude)
                Write-Debug ("-NestedModules Count:  {0}" -f ($NestedModules.Count))
            }
            #endregion Get-NestedModules-List
        }

        Write-Debug ("Final -FileList count:        {0}" -f ($FileList.Count))
        Write-Debug ("Final -ModuleList count:      {0}" -f ($ModuleList.Count))
        Write-Debug ("Final -NestedModules count:   {0}" -f ($NestedModules.Count))
        #endregion Get-File-Lists

        #region Get-FileName-List
        $NestedModulesNames = [String[]]($NestedModules | %{$_.Name})
        $ModuleListNames    = [String[]]($ModuleList | %{$_.Name})
		$FileListNames      = [String[]]($FileList | %{$_.Name})
        #endregion Get-FileName-List

        #region Get-Module-PrivateData
        if (!($PrivateData))
        {
            $FilePath = ("PrivateData.txt")
            if(Test-Path -Path $FilePath -PathType Leaf)
            {
                $PrivateData = ([String]::Concat(((Get-Content -Path $FilePath).Trim())))
            }
        }
        #endregion Get-Module-PrivateData

        Write-Host

        #region UpdateConsoleWithFileLists
        Write-Host ("Files to be included in module:") -ForegroundColor Green
        Write-Host

        # -FileList
        Write-Host ("{0}{1}" -f $OneTabIndent,"-FileList") -ForegroundColor Green
        $FileListNames | %{Write-Host ("{0}{1}" -f $TwoTabIndent,$_)}
        Write-Host

        # -ModuleList
        Write-Host ("{0}{1}" -f $OneTabIndent,"-ModuleList") -ForegroundColor Green
        $ModuleListNames | %{Write-Host ("{0}{1}" -f $TwoTabIndent,$_)}
        Write-Host

        # -NestedModules
        Write-Host ("{0}{1}" -f $OneTabIndent,"-NestedModules") -ForegroundColor Green
        $NestedModulesNames | %{Write-Host ("{0}{1}" -f $TwoTabIndent,$_)}
        #endregion

        Write-Host

        #region Retrieve functions to export
        if(!($FunctionsToExport))
        {
            # If none supplied by the commmand line
            Write-Host ("No functions passed via -FunctionsToExport parameter, searching ") -ForegroundColor White -NoNewline
            Write-Host ("{0} " -f (@($NestedModules).Count)) -ForegroundColor Green -NoNewline
            Write-Host ("files specified by -NestedModules parameter") -ForegroundColor White
            Write-Host

            :FunctionExport foreach($File in $NestedModules)
            {
                Write-Host ("{0}Parsing " -f $OneTabIndent) -NoNewline
                Write-Host ("{0}" -f $File.Name) -ForegroundColor Green -NoNewline
                Write-Host (" ... ") -NoNewline

                $FoundFunctions = ([String[]] (Read-PsExportModuleList -FilePath ($File.FullName) -ReturnAsArray))
                if($FoundFunctions)
                {
                    if($FoundFunctions.Count -gt 0)
                    {
                        $FunctionsToExport += @($FoundFunctions)
                        Write-Host ("Complete ") -ForegroundColor 'Green' -NoNewline
                        Write-Host ("(In File: {0}, Total: {1})" -f ($FoundFunctions.Count),($FunctionsToExport.Count))

                        Write-Host
                        Write-Host ("{0}Function List for " -f $TwoTabIndent) -NoNewline
                        Write-Host ("{0}" -f $File.Name) -NoNewline -ForegroundColor 'Green'
                        Write-Host (":")

                        $FoundFunctions | foreach {
                            Write-Host ("{0}{1}" -f $ThreeTabIndent,$_)
                        }
                        Write-Host
    				}
                }
                elseif($FunctionsToExport)
                {
                    Write-Host ("Warning ") -ForegroundColor 'Yellow' -NoNewline
                    Write-Host ("(In File: 0, Total: {0})" -f ($FunctionsToExport.Count))
				}
                else
                {
                    Write-Host ("Warning ") -ForegroundColor 'Yellow' -NoNewline
                    Write-Host ("(In File: 0, Total: 0)")
				}
			}
		}
        #endregion

        Write-Host

        #region RequiredModules
        if($IncludeStandardModules.IsPresent)
        {
            # Add list of modules to list passed by command line
            $RequiredModules += (@("DnsClient","NetAdapter","NetSecurity","NetConnection","NetTCPIP","PSDiagnostics","SmbShare") | Sort)
		}

        # Update console
        Write-Host ("Required Modules:") -ForegroundColor Green
        $RequiredModules | %{Write-Host ("{0}{1}" -f $FiveTabIndent,$_)}
        #endregion

        Write-Host

        #region Show-Module-Meta-Information
        # Echo meta information about manifest to console

        Write-Host ("Module Meta Information") -ForegroundColor Green
        $FmtIndnt = ([int](-17))
        Write-Host ("{0}{1,$FmtIndnt}: {2}" -f $OneTabIndent,"Filename",$Path)
        Write-Host ("{0}{1,$FmtIndnt}: {2}" -f $OneTabIndent,"Author",$Author)
        Write-Host ("{0}{1,$FmtIndnt}: {2}" -f $OneTabIndent,"Company",$CompanyName)
        Write-Host ("{0}{1,$FmtIndnt}: {2}" -f $OneTabIndent,"Copyright",$Copyright)
        Write-Host ("{0}{1,$FmtIndnt}: {2}" -f $OneTabIndent,"Description",$Description)
        Write-Host ("{0}{1,$FmtIndnt}: {2}" -f $OneTabIndent,"CommandPrefix",$CommandPrefix)

        Write-Host ("{0}{1,$FmtIndnt}: {2}" -f $OneTabIndent,"PS Version",$PowerShellVersion)
        Write-Host ("{0}{1,$FmtIndnt}: {2}" -f $OneTabIndent,"PS Host Version",$PowerShellHostVersion)
        Write-Host ("{0}{1,$FmtIndnt}: {2}" -f $OneTabIndent,"Module Version",$ModuleVersion)

        if($CLRVersion -ne $null)
        {
            Write-Host ("{0}{1,$FmtIndnt}: {2}" -f $OneTabIndent,"CLR Version",$CLRVersion)
		}

        if($PrivateData)
        {
            Write-Host ("{0}{1,$FmtIndnt}:`n{2}" -f $OneTabIndent,"PrivateData",$PrivateData)
		}
        #endregion Show-Module-Meta-Information


        #region Set-BuildCommand-File-Contents
        Set-Content -Path "BuildCommand-OOB.txt" -Force -Value `
        (("New-ModuleManifest `
            -Path $Path `
            -FileList $FileListNames `
            -ModuleList $ModuleListNames `
            -NestedModules $NestedModulesNames `
            -Author $Author `
            -ClrVersion $CLRVersion `
            -CompanyName $CompanyName `
            -Copyright $Copyright `
            -DefaultCommandPrefix $CommandPrefix `
            -Description $Description `
            -ModuleVersion $ModuleVersion `
            -PowerShellHostVersion $PowerShellHostVersion `
            -PowerShellVersion $PowerShellVersion  `
            -PrivateData $PrivateData `
            -RequiredModules $RequiredModules `
            -FunctionsToExport $FunctionsToExport").Trim())
        #endregion Set-BuildCommand-File-Contents


        #region Create-Module-Manifest
        New-ModuleManifest `
            -Path $Path `
            -FileList $FileListNames `
            -ModuleList $ModuleListNames `
            -NestedModules $NestedModulesNames `
            -Author $Author `
            -ClrVersion $CLRVersion `
            -CompanyName $CompanyName `
            -Copyright $Copyright `
            -DefaultCommandPrefix $CommandPrefix `
            -Description $Description `
            -ModuleVersion $ModuleVersion `
            -PowerShellHostVersion $PowerShellHostVersion `
            -PowerShellVersion $PowerShellVersion  `
            -PrivateData $PrivateData `
            -RequiredModules $RequiredModules `
            -FunctionsToExport $FunctionsToExport
        #endregion Create-Module-Manifest
    }
}

function Read-PsExportModuleList
{
    [CmdletBinding()]

    Param
    (
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        # Path to PowerShell Module file
        [String] $FilePath
        ,
        [Parameter()]
        # Return the results as a [String[]] instead of a [String]
        [Switch] $ReturnAsArray
    )

    PROCESS
    {
        $StartLine = ('#region Public-Functions')
        $EndLine = ('#endregion Public-Functions')

        Write-Debug ("Parameter values")
        Write-Debug ("`t$FilePath")
        Write-Debug ("`t$StartLine")
        Write-Debug ("`t$EndLine")

        # Will throw an exception if it isn't accessible, so no try catch
        $Path = (Get-Item -Path $FilePath)

        Write-Debug ("Getting file contents")
        $FileContents = [String[]] @(Get-Content -Path $Path)
        Write-Debug ("{0} lines read" -f ($FileContents.Count))

        # Find the line numbers for #region PublicCmdlets and #endregion PublicCmdlets
        [int]$FirstLine = 0
        [int]$LastLine = 0

        #region Find-First-And-Last-Line-Numbers
        Write-Debug ("Searching for $StartLine and $EndLine numbers")
        $LineNumber = ([int]0)
        :FindLineNumbers foreach($Line in $FileContents)
        {
            #Write-Debug ("`tCurrent Line Number: $LineNumber")
            if(($FileContents[$LineNumber].Trim()) -eq $StartLine)
            {
                Write-Debug ("`tFound {0} on line {1}" -f $StartLine,$LineNumber)
                $FirstLine = $LineNumber
			}
            elseif(($FileContents[$LineNumber].Trim()) -eq $EndLine)
            {
                Write-Debug ("`tFound {0} on line {1}" -f $EndLine,$LineNumber)
                $LastLine = $LineNumber
			}

            if(($FirstLine -ne 0) -and ($LastLine -ne 0))
            {
                break FindLineNumbers
			}
            $LineNumber++
		}
        #endregion Find-First-And-Last-Line-Numbers

        #region Search-File-For-Function-Names
        Write-Debug ("Searching for function names")
        $FunctionNames = ([String[]]@())
        $LineNumber = ([int]0)
        :FindFunctions foreach($Line in $FileContents)
        {
            #Write-Debug ("`tCurrent Line Number: $LineNumber")
            if($LineNumber -ge $LastLine)
            {
                break FindFunctions
			}

            if($FileContents[$LineNumber].StartsWith("function"))
            {
                Write-Debug ("`tLine {0} starts with 'function'" -f $LineNumber)
                if(($LineNumber -gt $FirstLine) -and ($LineNumber -lt $LastLine))
                {
                    Write-Debug ("`tLine {0} is between {1} and {2}" -f $LineNumber,$FirstLine,$LastLine)
                    $SubStartIndex = [int](('function'.Length) + 1)
                    Write-Debug ("`tSubString Start Index: {0}" -f $SubStartIndex)
                    $LineContents = ($FileContents[$LineNumber])
                    Write-Debug ("`tLine contents: {0}" -f $LineContents)
                    $SubEndIndex = [int]($LineContents.IndexOf(' ',$SubStartIndex))
                    Write-Debug ("`tSub End Index: {0}" -f $SubEndIndex)

                    if($SubEndIndex -gt $SubStartIndex)
                    {
                        Write-Debug ("`tSub End Index ({0}) is greater than Sub Start Index ({1})" -f $SubEndIndex,$SubStartIndex)
                        $SubLength = [int]($SubEndIndex - $SubStartIndex)
                    }
                    else
                    {
                        Write-Debug ("`tSub End Index ({0}) is less than Sub Start Index ({1})" -f $SubEndIndex,$SubStartIndex)
                        $SubLength = [int]($LineContents.Length - $SubStartIndex)
    				}

                    Write-Debug ("`tSub Length is {0}" -f $SubLength)

#                    $FunctionNames = ([String]::Concat($FunctionNames,(($LineContents.SubString($SubStartIndex,$SubLength)) + ",")))
                    $FunctionNames += (($LineContents.SubString($SubStartIndex,$SubLength)).Trim())
                    #Write-Debug ("`tFunction is:`r`n{0}" -f $FunctionNames)
				}
			}
            $LineNumber++
		}
        #endregion Search-File-For-Function-Names

        $FunctionNames = ([String[]] ($FunctionNames | Sort))

        if($ReturnAsArray.IsPresent)
        {
            Write-Output ($FunctionNames) -NoEnumerate
		}
        else
        {
            Write-Output ($FunctionNames -join ',') -NoEnumerate
		}

        Write-Debug ("PROCESS:Leaving:  [Get-ExportModuleMemberList]")
    }
}
#>
#endregion Manifests

function Get-EnumContents
{
    [CmdletBinding()]

    Param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        # Namespace of Enum, e.g. System.Management.Automation.PSCredentialUIOptions
        [String] $Namespace

    )

    PROCESS
    {
		[int]$ArrayCount = ([Enum]::GetNames($Namespace).Count)

        #region Write-Debug
        Write-Debug ("Enum Name:      {0}" -f ($Namespace))
        Write-Debug ("Total Members:  {0}" -f ($ArrayCount))
        #endregion Write-Debug

        #region Loop-Enum-Contents
        for($i=0,$i -lt $ArrayCount;$i++)
        {
            #region Write-Debug
            Write-Debug ("Iteration: {0}" -f ($i))
            #endregion Write-Debug

            Write-Output ([PsCustomObject]@{
                Name = ([Enum]::GetNames($Namespace)[$i])
                Value = ([Enum]::GetValues($Namespace)[$i])
            })
        }
    }
}

function Get-VersionNumber
{
    [CmdletBinding()]
    [OutputType([System.Version])]
    param()

    process
    {
        Write-Output ([System.Version] ("{0}.{1}.{2}.{3}" -f `
            ($script:NvnMajor),`
            ($script:NvnMinor),`
            ($script:NvnBuild),`
            ($script:NvnRevision)
        ))
    }
}

function New-PsProxyCommand
{
    [CmdletBinding(DefaultParameterSetName='Clipboard')]
    [OutputType([System.String])]

    param
    (
        [Parameter(ParameterSetName=�OutToFile�)]
        [ValidateNotNullOrEmpty()]
        # Path and filename to write proxy command to
        [System.IO.FileInfo] $OutputPath
        ,
        [Parameter(ParameterSetName='Clipboard')]
        [Switch]
        # Places the command on the keyboard as opposed to writing it to file
        $Clipboard
        ,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        # Name of command to proxy
        [String] $CommandName
    )

    process
    {
        $functionText = [System.Management.Automation.ProxyCommand]::Create((New-Object System.Management.Automation.CommandMetaData (Get-Command -Name $CommandName)))

        if ($PSCmdlet.ParameterSetName -eq 'Clipboard')
        {
            Set-Clipboard -Value $functionText
            Write-Verbose ('Proxy for command {0} has been placed on the clipboard' -f $CommandName)
        }
        else
        {
            Write-Verbose ("Proxy command for '{0}'has been written to {1}" -f $CommandName,$OutputPath.FullName)
            Set-Content -LiteralPath $OutputPath.FullName -Value $functionText -Force
        }
    }
}

function New-VersionNumber
{
    [CmdletBinding(DefaultParameterSetName='NewVersion')]
    [OutputType([System.Version])]

    Param
    (

        [Parameter(ParameterSetName='NewVersion')]
        [ValidateNotNullOrEmpty()]
        # Current major version number
        [int] $Major = $script:NvnMajor
        ,
        [Parameter(ParameterSetName='NewVersion')]
        [ValidateNotNullOrEmpty()]
        # Current minor version number
        [int] $Minor = $script:NvnMinor
        ,
        [Parameter(ParameterSetName='NewVersion')]
        [ValidateNotNullOrEmpty()]
        # Current revision Number
        [int] $Revision = $script:NvnRevision
        ,
        [Parameter(
            Mandatory=$true,
            ParameterSetName='IncrementVersion')]
        [ValidateNotNullOrEmpty()]
        # Current version Number
        [Version] $Version
        ,
        [Parameter()]
        # Increment major version number
        [Switch] $IncrementMajor
        ,
        [Parameter()]
        # Increment minor version number
        [Switch] $IncrementMinor
    )

    PROCESS
    {
        $ReturnVersion = ([System.Version]::new())

        switch ($PSCmdlet.ParameterSetName)
        {
            'NewVersion'
            {
                #region Update-Script-Variables
                if ($Major -gt $script:NvnMajor)
                {
                    $script:NvnMajor = $Major
                }

                if ($Minor -gt $script:NvnMinor)
                {
                    $script:NvnMinor = $Minor
                }

                if ($Revision -gt $script:NvnRevision)
                {
                    $script:NvnRevision = $Revision
                }

                if ($IncrementMajor.IsPresent)
                {
                    $script:NvnMajor++
                }

                if ($IncrementMinor.IsPresent)
                {
                    $script:NvnMinor++
                }

                $script:NvnRevision++
                #endregion Update-Script-Variables

                #region Update-Version-Object
                $ReturnVersion = ([System.Version] ("{0}.{1}.{2}.{3}" -f `
                    ($script:NvnMajor),`
                    ($script:NvnMinor),`
                    ($script:NvnBuild),`
                    ($script:NvnRevision)
                ))
                #endregion Update-Version-Object
            }
            'IncrementVersion'
            {
                #region Update-Script-Variables
                $script:NvnMajor = $Version.Major
                $script:NvnMinor = $Version.Minor
                $script:NvnBuild = $Version.Build
                $script:NvnRevision = $Version.Revision

                if ($IncrementMajor.IsPresent)
                {
                    $script:NvnMajor++
                }

                if ($IncrementMinor.IsPresent)
                {
                    $script:NvnMinor++
                }

                $script:NvnRevision++
                #endregion Update-Script-Variables

                #region Update-Version-Object
                $ReturnVersion = ([System.Version] ("{0}.{1}.{2}.{3}" -f `
                    ($script:NvnMajor),`
                    ($script:NvnMinor),`
                    ($script:NvnBuild),`
                    ($script:NvnRevision)
                ))
                #endregion Update-Version-Object
            }
        }

        Write-Output ($ReturnVersion)
    }
}

function Reset-VersionNumber
{
    [int]$script:NvnMajor = 1
    [int]$script:NvnMinor = 0
    [int]$script:NvnBuild = (Get-Date -Format 'yyMMdd')
    [int]$script:NvnRevision = 0
}

function Show-PsMembers
{
    [CmdletBinding()]

    Param
    (

        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [PSObject]
        $InputObject

    )

    BEGIN
    {
        $AllMembers = [object[]]@()
	}

    PROCESS
    {
        foreach($Item in $MemberCollection)
        {
            $FormattedObject = [PSCustomObject]@{
                'Name'          = ($Item.Name)
                'MemberType'    = ($Item.MemberType)
                'Definition'    = ([string](($Item.Definition.Replace('),',')|').Split('|').Trim()) -join "`r`n"))
                'TypeName'      = ($Item.TypeName)
			}

            $AllMembers += $FormattedObject
		}
    }

    END
    {
        $AllMembers | Out-GridView
	}
}
#endregion Public-Functions

#region Private-Functions
#region For: New-PsExampleCallstack
function Enter-FrameOne
{
    PROCESS
    {
        [string]$HiWorld = "Hello World!"
        return (Enter-FrameTwo)
    }
}

function Enter-FrameTwo
{
    PROCESS
    {
        [int[]]$IntArray = [int[]] (1..10)
        return (Enter-FrameThree)
    }
}

function Enter-FrameThree
{
    PROCESS
    {
        [string]$Username = ($Env:USERNAME)
        return (Get-PSCallStack)
    }
}
#endregion For: New-PsExampleCallstack

#region For: New-PsExampleException
function Enter-ErrorFrameOne
{
    [CmdletBinding()]
    Param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Object] $Exception

    )

    PROCESS
    {
        if($Exception)
        {
            Enter-ErrorFrameTwo -Exception $Exception
        }
        else
        {
            Enter-ErrorFrameTwo
        }
    }
}

function Enter-ErrorFrameTwo
{
    [CmdletBinding()]
    Param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Object] $Exception
    )

    PROCESS
    {
        if($Exception)
        {
            Enter-ErrorFrameThree -Exception $Exception
        }
        else
        {
            Enter-ErrorFrameThree
        }
    }
}

function Enter-ErrorFrameThree
{
    [CmdletBinding()]
    Param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Object] $Exception

    )

    PROCESS
    {
        if($Exception)
        {
            throw $Exception
        }
        else
        {
            try
            {
            	1/0
            }
            catch [Exception]
            {
                $Ex = $_
                throw $Ex
            }
        }
    }
}
#endregion For: New-PsExampleException
#endregion Private-Functions