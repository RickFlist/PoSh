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
        #>
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

       # <#
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
        #>

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