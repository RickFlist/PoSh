#region Configure-Module
#Requires -Version 5.0
#Requires -RunAsAdministrator
Set-StrictMode -Version Latest
#endregion Configure-Module
#region Script-Variables
[string]$script:DebugPreviousLineMoniker = ([string]::Empty)
[bool]$script:DebugPrvsLineMatch = ($false)
#endregion Script-Variables

#region Public-Functions
function Write-Debug
{
     [CmdletBinding(
          SupportsShouldProcess = $false,
          ConfirmImpact = "Low",
          HelpUri = 'http://go.microsoft.com/fwlink/?LinkID=113424',
          RemotingCapability = 'None'
     )]

     Param
     (

          [Parameter(
               Position = 00,
               Mandatory = $true,
               ValueFromPipeline = $true,
               HelpMessage = "Message to write to debug stream"
          )]
          [Alias('Msg')]
          [AllowEmptyString()]
          [string]
          $Message
          ,
          [Parameter(
               Position = 01,
               HelpMessage = "Number of tabs between the timestap and the message"
          )]
          [ValidateNotNullOrEmpty()]
          [Int]
          $Tabs = 0
          ,
          [Parameter(
               Position = 02,
               HelpMessage = "Number of new lines to enter after the message"
          )]
          [ValidateNotNullOrEmpty()]
          [int] $NewLines = 1
          ,
          [Parameter(
               HelpMessage = "No script information header"
          )]
          [ValidateNotNullOrEmpty()]
          [Switch] $NoHeader

     )

     BEGIN
     {
          #region Parameter-Stuff
          try
          {
               ## Access the REAL Foreach-Object command, so that command wrappers do not interfere with this script
               $foreachObject = $executionContext.InvokeCommand.GetCmdlet("Microsoft.PowerShell.Core\Foreach-Object")
               $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Write-Debug',[System.Management.Automation.CommandTypes]::Cmdlet)

               $wrappedCmd.Visibility = ([System.Management.Automation.SessionStateEntryVisibility]::Private)

               ## TargetParameters represents the hashtable of parameters that we will pass along to the wrapped command
               $targetParameters = @{}
               $PSBoundParameters.GetEnumerator() |
                    & $foreachObject {
                    if ($command.Parameters.ContainsKey($_.Key))
                    {
                         $targetParameters.Add($_.Key, $_.Value)
                    }
               }

               ## finalPipeline represents the pipeline we wil ultimately run
               $newPipeline = { & $wrappedCmd @targetParameters }
               $finalPipeline = $newPipeline.ToString()

               $steppablePipeline = [ScriptBlock]::Create($finalPipeline).GetSteppablePipeline()
               $steppablePipeline.Begin($PSCmdlet)
          }
          catch [Exception]
          {
               $Ex = $_
               throw $Ex
          }
          #endregion Parameter-Stuff

          #region Create-Indent-String
          function New-Indent
          {
               param
               (
                    [Parameter(
                         Position = 00
                    )]
                    [int] $Indents = 0
                    ,
                    [Parameter(
                         Position = 01
                    )]
                    [ValidateNotNullOrEmpty()]
                    [string] $IndentChar = ' '
               )

               PROCESS
               {
                    [int]$IndentLngth = 3
                    [string]$IndentString = ([string]::Empty)

                    if ($Indents -gt 0)
                    {
                         [string]$IndentString = ($IndentChar * ($Indents * $IndentLngth))
                    }
                    else
                    {
                         [string]$IndentString = ($IndentChar)
                    }

                    Write-Output ($IndentString)
               }
          }
          #endregion Create-Indent-String
     }

     PROCESS
     {
          try
          {
               [bool]$SkipHeader = ($NoHeader.IsPresent)
               [bool]$PrvsLineMatch = ($script:DebugPrvsLineMatch)

               #region Check-Ps-Host-Name
               switch ($Host.Name)
               {
                    'ConsoleHost'
                    {
                         $NewLines++
                    }
               }
               #endregion Check-Ps-Host-Name

               #region Create-Formatting-Strings
               $CarriageReturns = ("`r`n" * $NewLines)
               $StckDepth = [int](@(Get-PSCallStack).Count - 1)
               $IndentStr = (New-Indent -Indents ($StckDepth) -IndentChar '-')
               $DbgMsgIndent = ("       |{0}" -f `
                    (New-Indent -Indents ($StckDepth) -IndentChar '-')
               )
               #endregion Create-Formatting-Strings

               #region Get-Caller-Info-From-Callstack
               $CStack = @(Get-CallStack -StackIndex 2)

               if ($CStack)
               {
                    $TopLayer = ($CStack[0])
                    if ($TopLayer.ScriptName)
                    {
                         [System.IO.FileInfo]$CallerFile = ($TopLayer.ScriptName)
                    }
                    else
                    {
                         $CallerFile = ([PsCustomObject]@{
                                   'Name'     = ([string]('<No file>'))
                                   'FullName' = ([string]('<No file>'))
                              })
                    }

                    [string]$CallerCmdName = ($TopLayer.Command)
                    [int]$CallerLineNum = ($TopLayer.ScriptLineNumber)
               }
               #endregion Get-Caller-Info-From-Callstack

               #region Check-Previous-Execution
               [string]$LineMoniker = ("{0}|{1}|{2}" -f `
                    ($CallerFile.Name),`
                    ($CallerCmdName),`
                    ($CallerLineNum)
               )

               if ([string]::IsNullOrEmpty($script:DebugPreviousLineMoniker) -eq $true)
               {
                    $script:DebugPreviousLineMoniker = ($LineMoniker)
                    $script:DebugPrvsLineMatch = ($false)
               }
               elseif ($script:DebugPreviousLineMoniker -eq $LineMoniker)
               {
                    $SkipHeader = ($true)
                    $script:DebugPrvsLineMatch = ($true)
               }
               else
               {
                    $script:DebugPreviousLineMoniker = ($LineMoniker)
                    $script:DebugPrvsLineMatch = ($false)
               }
               #endregion Check-Previous-Execution

               #region Create-Console-Message
               #region Header-Included
               if (!($SkipHeader))
               {
                    #                $MsgHeader = [string]("|$IndentStr [{0}]-[{1}]-[{2}\{3}]-[{4,4}]" -f `
                    $MsgHeader = [string]("|{0} [{1}]-[{2}]-[{3}\{4}]-[{5,4}]" -f `
                         ($IndentStr),`
                         (New-TimeStamp),`
                         ($StckDepth),`
                         ($CallerFile.Name),`
                         ($CallerCmdName),`
                         ($CallerLineNum)
                    )

                    $ConsoleMessage = ([string]("{0}`r`n{1} {2}{3}" -f `
                              ($MsgHeader),`
                              ($DbgMsgIndent),`
                              ($Message),`
                              ($CarriageReturns)
                         )
                    )
               }
               #endregion Header-Included
               #region Header-Omitted
               else
               {
                    $SubIndent = (New-Indent -Indents (2))
                    $ConsoleMessage = ([string]("{0}|{1} {2}{3}" -f `
                              ($SubIndent),`
                              ($IndentStr),`
                              ($Message),`
                              ($CarriageReturns)
                         )
                    )
               }
               #endregion Header-Omitted
               #endregion Create-Console-Message

               #region Output-Debug-Message
               if ($targetParameters.ContainsKey("Message"))
               {
                    $targetParameters.Message = ($ConsoleMessage)
               }
               else
               {
                    $targetParameters.Add('Message',$ConsoleMessage)
               }

               Microsoft.PowerShell.Utility\Write-Debug @targetParameters
               #endregion Output-Debug-Message
          }
          catch [Exception]
          {
               $Ex = $_
               throw $Ex
          }
     }

     end
     {
          try
          {

               #            $steppablePipeline.End()
          }
          catch [Exception]
          {
               $Ex = $_
               throw $Ex
          }
     }

     #region DynamicParam{}
     dynamicparam
     {
          ## Access the REAL Get-Command, Foreach-Object, and Where-Object commands, so that command wrappers
          ##      do not interfere with this script
          $getCommand = $executionContext.InvokeCommand.GetCmdlet("Microsoft.PowerShell.Core\Get-Command")
          $foreachObject = $executionContext.InvokeCommand.GetCmdlet("Microsoft.PowerShell.Core\Foreach-Object")
          $whereObject = $executionContext.InvokeCommand.GetCmdlet("Microsoft.PowerShell.Core\Where-Object")

          ## Find the parameters of the original command, and remove everything else from the bound parameter list
          ##      so we hide parameters the wrapped command does not recognize.
          $command = & $getCommand Write-Debug -Type Cmdlet
          $targetParameters = @{}
          $PSBoundParameters.GetEnumerator() |
               & $foreachObject {
               if ($command.Parameters.ContainsKey($_.Key))
               {
                    $targetParameters.Add($_.Key, $_.Value)
               }
          }

          ## Get the argument list as it would be passed to the target command
          $argList = @($targetParameters.GetEnumerator() |
                    Foreach-Object { "-$($_.Key)"; $_.Value })

          ## Get the dynamic parameters of the wrapped command, based on the arguments to this command
          $command = $null
          try
          {
               $command = & $getCommand Write-Debug -Type Cmdlet -ArgumentList $argList
          }
          catch [Exception]
          {}

          $dynamicParams = @($command.Parameters.GetEnumerator() |
                    & $whereObject { $_.Value.IsDynamic })

          ## For each of the dynamic parameters, add them to the dynamic parameters that we return.
          if ($dynamicParams.Length -gt 0)
          {
               $paramDictionary = New-Object Management.Automation.RuntimeDefinedParameterDictionary
               foreach ($param in $dynamicParams)
               {
                    $param = $param.Value
                    $arguments = $param.Name, $param.ParameterType, $param.Attributes
                    $newParameter = New-Object Management.Automation.RuntimeDefinedParameter $arguments
                    $paramDictionary.Add($param.Name, $newParameter)
               }

               return $paramDictionary
          }
     }
     #endregion

     <#
    .ForwardHelpTargetName Write-Debug
    .ForwardHelpCategory Cmdlet
    #>
}

function Write-Information
{
     [CmdletBinding(HelpUri = 'http://go.microsoft.com/fwlink/?LinkId=525909', RemotingCapability = 'None')]
     param(
          [Parameter(Mandatory = $true, Position = 0)]
          [Alias('Msg')]
          [System.Object]
          ${MessageData},

          [Parameter(Position = 1)]
          [string[]]
          ${Tags})

     begin
     {
          try
          {
               $outBuffer = $null
               if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
               {
                    $PSBoundParameters['OutBuffer'] = 1
               }
               $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Write-Information', [System.Management.Automation.CommandTypes]::Cmdlet)
               $scriptCmd = {& $wrappedCmd @PSBoundParameters }
               $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
               $steppablePipeline.Begin($PSCmdlet)
          }
          catch
          {
               throw
          }
     }

     process
     {
          $outString = ('{0}: {1}' -f (Get-Date -Format 'MM/dd HH:mm:ss'), $MessageData)
          $PSBoundParameters['MessageData'] = $outString
          Microsoft.PowerShell.Utility\Write-Information @PSBoundParameters
     }

     <#

    .ForwardHelpTargetName Microsoft.PowerShell.Utility\Write-Information
    .ForwardHelpCategory Cmdlet

    #>

}

function Write-Verbose
{
     [CmdletBinding(HelpUri = 'http://go.microsoft.com/fwlink/?LinkID=113429', RemotingCapability = 'None')]
     param(
          [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
          [Alias('Msg')]
          [AllowEmptyString()]
          [string]
          ${Message})

     begin
     {
          try
          {
               $outBuffer = $null
               if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
               {
                    $PSBoundParameters['OutBuffer'] = 1
               }
               $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Write-Verbose', [System.Management.Automation.CommandTypes]::Cmdlet)
               $scriptCmd = {& $wrappedCmd @PSBoundParameters }
               $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
               $steppablePipeline.Begin($PSCmdlet)
          } catch
          {
               throw
          }
     }

     process
     {
          try
          {
               $outputString = ('{0}: {1}' -f (Get-Date -Format 'MM/dd HH:mm:ss'),$Message)
               Microsoft.PowerShell.Utility\Write-Verbose -Message $outputString
          }
          catch [Exception]
          {
               $Ex = $_
               throw $Ex
          }
          <#
        try {
            $steppablePipeline.Process($_)
        } catch {
            throw
        }
        #>
     }
     <#

    .ForwardHelpTargetName Microsoft.PowerShell.Utility\Write-Verbose
    .ForwardHelpCategory Cmdlet

    #>
}

function Write-Host
{

     #region Parameters
     Param
     (
          [CmdletBinding(
               SupportsShouldProcess = $false,
               ConfirmImpact = "Low"
          )]

          ### ParameterSet - Setless Parameters ###

          [Parameter(Position = 00, ValueFromPipeline = $true, ValueFromRemainingArguments = $true)]
          [System.Object]
          $Object,

          #region NP-$Tabs
          [Parameter(
          )]
          [ValidateNotNullOrEmpty()]
          [Int]
          $Tabs = 0
          #endregion
          ,
          [switch]
          $NoNewline,

          [System.Object]
          $Separator,

          [System.ConsoleColor]
          $ForegroundColor,

          [System.ConsoleColor]
          $BackgroundColor,

          [System.ConsoleColor]
          $DateTimeColor = ([System.ConsoleColor]::DarkGray)
          ,
          #region SW-$NoTimeStamp
          [Parameter(
               HelpMessage = "Supresses timestamp on console output"
          )]
          [Switch]
          $NoTimeStamp
          #endregion
     )
     #endregion Parameters

     #region Begin{}
     begin
     {
          #region ParameterStuff
          try
          {
               ## Access the REAL Foreach-Object command, so that command wrappers do not interfere with this script
               $foreachObject = $executionContext.InvokeCommand.GetCmdlet("Microsoft.PowerShell.Core\Foreach-Object")
               $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Write-Host',[System.Management.Automation.CommandTypes]::Cmdlet)
               #            $wrappedCmd.Visibility = ([System.Management.Automation.SessionStateEntryVisibility]::Private)

               ## TargetParameters represents the hashtable of parameters that we will pass along to the wrapped command
               $targetParameters = @{}
               $PSBoundParameters.GetEnumerator() |
                    & $foreachObject {
                    if ($command.Parameters.ContainsKey($_.Key))
                    {
                         $targetParameters.Add($_.Key, $_.Value)
                    }
               }

               ## finalPipeline represents the pipeline we wil ultimately run
               $newPipeline = { & $wrappedCmd @targetParameters }
               $finalPipeline = $newPipeline.ToString()

               $steppablePipeline = [ScriptBlock]::Create($finalPipeline).GetSteppablePipeline()
               $steppablePipeline.Begin($PSCmdlet)
          }
          catch [Exception]
          {
               $Ex = $_
               throw $Ex
          }
          #endregion

          #region CreateIndent
          [int]$TabSpaces = 4
          [string]$IndentString = ([string]::Empty)
          if ($Tabs -gt 0)
          {
               [string]$IndentString = (' ' * ($Tabs * $TabSpaces))
          }
          else
          {
               [string]$IndentString = (' ')
          }
          #endregion
     }
     #endregion

     #region Process{}
     process
     {
          try
          {
               if (!($NoTimeStamp.IsPresent))
               {
                    $MessagePrefix = [string]("{0}:>{1}" -f (New-TimeStamp),($IndentString))
                    Microsoft.PowerShell.Utility\Write-Host -Object $MessagePrefix -ForegroundColor $DateTimeColor -NoNewline
               }

               $ConsoleMessage = ([string]($Object))
               if ($targetParameters.ContainsKey("Object"))
               {
                    $targetParameters.Object = ($ConsoleMessage)
               }

               Microsoft.PowerShell.Utility\Write-Host @targetParameters
               #$steppablePipeline.Process($targetParameters)
          }
          catch [Exception]
          {
               $Ex = $_
               throw $Ex
          }
     }
     #endregion

     #region End{}
     end
     {
          try
          {
               #$steppablePipeline.End()
          }
          catch [Exception]
          {
               $Ex = $_
               throw $Ex
          }
     }
     #endregion

     #region DynamicParam{}
     dynamicparam
     {
          ## Access the REAL Get-Command, Foreach-Object, and Where-Object commands, so that command wrappers
          ##      do not interfere with this script
          $getCommand = $executionContext.InvokeCommand.GetCmdlet("Microsoft.PowerShell.Core\Get-Command")
          $foreachObject = $executionContext.InvokeCommand.GetCmdlet("Microsoft.PowerShell.Core\Foreach-Object")
          $whereObject = $executionContext.InvokeCommand.GetCmdlet("Microsoft.PowerShell.Core\Where-Object")

          ## Find the parameters of the original command, and remove everything else from the bound parameter list
          ##      so we hide parameters the wrapped command does not recognize.
          $command = & $getCommand Write-Host -Type Cmdlet
          $targetParameters = @{}
          $PSBoundParameters.GetEnumerator() |
               & $foreachObject {
               if ($command.Parameters.ContainsKey($_.Key))
               {
                    $targetParameters.Add($_.Key, $_.Value)
               }
          }

          ## Get the argument list as it would be passed to the target command
          $argList = @($targetParameters.GetEnumerator() |
                    Foreach-Object { "-$($_.Key)"; $_.Value })

          ## Get the dynamic parameters of the wrapped command, based on the arguments to this command
          $command = $null
          try
          {
               $command = & $getCommand Write-Host -Type Cmdlet -ArgumentList $argList
          }
          catch [Exception]
          {}

          $dynamicParams = @($command.Parameters.GetEnumerator() |
                    & $whereObject { $_.Value.IsDynamic })

          ## For each of the dynamic parameters, add them to the dynamic parameters that we return.
          if ($dynamicParams.Length -gt 0)
          {
               $paramDictionary = New-Object Management.Automation.RuntimeDefinedParameterDictionary
               foreach ($param in $dynamicParams)
               {
                    $param = $param.Value
                    $arguments = $param.Name, $param.ParameterType, $param.Attributes
                    $newParameter = New-Object Management.Automation.RuntimeDefinedParameter $arguments
                    $paramDictionary.Add($param.Name, $newParameter)
               }

               return $paramDictionary
          }
     }
     #endregion

     <#
    .ForwardHelpTargetName Write-Host
    .ForwardHelpCategory Cmdlet
    #>
}
#endregion Public-Functions

#region Private-Functions
function Get-CallStack
{
     Param
     (
          [CmdletBinding(
               DefaultParameterSetName = "StackIndex",
               ConfirmImpact = "Low"
          )]

          [Parameter(
               Position = 00,
               Mandatory = $true,
               ParameterSetName = "CommandName"
          )]
          [ValidateNotNullOrEmpty()]
          # Trim stack until first instance of this command name is found
          [string]
          $CommandName
          ,
          [Parameter(
               Position = 00,
               ParameterSetName = "StackIndex"
          )]
          [ValidateNotNullOrEmpty()]
          # Number of stacks to remove from top of stack
          [int]
          $StackIndex = 1
     )

     PROCESS
     {
          # Return Value
          [System.Management.Automation.CallStackFrame[]]$ReturnVal = ([System.Management.Automation.CallStackFrame[]]@())

          # Get raw callstack
          $CStack = @(Get-PSCallStack)

          #region ParameterSet-Specific-Actions
          switch ($PsCmdlet.ParameterSetName)
          {
               "CommandName"
               {
                    # Find index using command name
                    [int]$StackIndex = 0
                    :FindCommand foreach ($Layer in $CStack)
                    {
                         if ($Layer.Command -eq $CommandName)
                         {
                              break FindCommand
                         }
                         $StackIndex++
                    }

                    break
               }
               "StackIndex" { break }
          }

          $CsEndIndex = ($CStack.Count - 1)

          $ReturnVal = @( $CStack[$StackIndex..$CsEndIndex] )

          Write-Output ($ReturnVal)
     }
     #endregion Process {}
}

function New-TimeStamp
{
     param
     (
          #region 00-$Formmat
          [Parameter(Position = 00)]
          [ValidateNotNullOrEmpty()]
          [string]
          $Format = ('MM/dd HH:mm:ss')
          #endregion
     )

     #REGION Process {}
     PROCESS
     {
          Write-Output ((Get-Date).ToString($Format))
     }
     #ENDREGION
}
#endregion Private-Functions