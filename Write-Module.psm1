#region Script-Variables
[string]$script:DebugPreviousLineMoniker = ([string]::Empty)
[bool]$script:DebugPrvsLineMatch = ($false)
#endregion Script-Variables

#region Public-Functions
function Write-Debug
{
    [CmdletBinding(
        SupportsShouldProcess=$false,
        ConfirmImpact = "Low",
        HelpUri='http://go.microsoft.com/fwlink/?LinkID=113424',
        RemotingCapability='None'
    )]

    Param
    (

    [Parameter(
        Position=00,
        Mandatory=$true,
        ValueFromPipeline=$true,
        HelpMessage="Message to write to debug stream"
    )]
    [Alias('Msg')]
    [AllowEmptyString()]
    [string]
    $Message
    ,
    [Parameter(
        Position=01,
        HelpMessage="Number of tabs between the timestap and the message"
    )]
    [ValidateNotNullOrEmpty()]
    [Int]
    $Tabs = 0
    ,
    [Parameter(
        Position=02,
        HelpMessage="Number of new lines to enter after the message"
    )]
    [ValidateNotNullOrEmpty()]
    [int] $NewLines = 1
    ,
    [Parameter(
        HelpMessage="No script information header"
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
                    if($command.Parameters.ContainsKey($_.Key))
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
                    Position=00
                )]
                [int] $Indents = 0
                ,
                [Parameter(
                    Position=01
                )]
                [ValidateNotNullOrEmpty()]
                [string] $IndentChar = ' '
            )
            
            PROCESS
            {
                [int]$IndentLngth = 3
                [string]$IndentString = ([string]::Empty)
                
                if($Indents -gt 0)
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
            $StckDepth      = [int](@(Get-PSCallStack).Count -1)
            $IndentStr  = (New-Indent -Indents ($StckDepth) -IndentChar '-')
            $DbgMsgIndent   = ("       |{0}" -f `
                (New-Indent -Indents ($StckDepth) -IndentChar '-')
            )
            #endregion Create-Formatting-Strings
            
            #region Get-Caller-Info-From-Callstack
            $CStack = @(Get-CallStack -StackIndex 2)
            
            if ($CStack)
            {
                $TopLayer = ($CStack[0])
                if($TopLayer.ScriptName)
                {
                    [System.IO.FileInfo]$CallerFile = ($TopLayer.ScriptName)
                }
                else
                {
                    $CallerFile = ([PsCustomObject]@{
                        'Name'      = ([string]('<No file>'))
                        'FullName'  = ([string]('<No file>'))
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
            
            if([string]::IsNullOrEmpty($script:DebugPreviousLineMoniker) -eq $true)
            {
                $script:DebugPreviousLineMoniker = ($LineMoniker)
                $script:DebugPrvsLineMatch = ($false)
            }
            elseif($script:DebugPreviousLineMoniker -eq $LineMoniker)
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
            if(!($SkipHeader))
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
            if($targetParameters.ContainsKey("Message"))
            {
                $targetParameters.Message = ($ConsoleMessage)
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
                if($command.Parameters.ContainsKey($_.Key))
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

function Set-DebugPreference
{
    [CmdletBinding()]

    Param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.ActionPreference]
        $Preference
    )

    Process
    {
        $Global:DebugPreference = $Preference
    }
}

function Set-InformationPreference
{
    [CmdletBinding()]

    Param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.ActionPreference]
        $Preference
    )

    Process
    {
        $Global:InformationPreference = $Preference
    }
}
#endregion Public-Functions

#region Private-Functions
function Get-CallStack
{
    #region Function-Parameters
    Param
    (
    [CmdletBinding(
        DefaultParameterSetName="StackIndex",
        SupportsShouldProcess=$false,
        ConfirmImpact = "Low"        
    )]
    
    ### ParameterSet - CommandName Function-Parameters ###
    
    #region 00 - $CommandName
    [Parameter(
        Position=00,
        Mandatory=$true,
        ParameterSetName="CommandName",
        HelpMessage="Trim stack until first instance of this command name is found"
    )]
    [ValidateNotNullOrEmpty()]
    [string] $CommandName
    #endregion -- - $CommandName

    ### ParameterSet - StackIndex Function-Parameters ###
    ,
    #region 00 - $StackIndex
    [Parameter(
        Position=00,
        ParameterSetName="StackIndex",
        HelpMessage="Number of stacks to remove from top of stack"
    )]
    [ValidateNotNullOrEmpty()]
    [int] $StackIndex = 1
    #endregion -- - $StackIndex
    
    )
    #endregion Function-Parameters
    
    #region Process {}
    PROCESS
    {
        # Return Value
        [System.Management.Automation.CallStackFrame[]]$ReturnVal = ([System.Management.Automation.CallStackFrame[]]@())
        
        #region Get-PsCallStack
        $CStack = @(Get-PSCallStack)
        #endregion Get-PsCallStack

        #region ParameterSet-Specific-Actions
        switch ($PsCmdlet.ParameterSetName)
        {
            #region ParameterSet-CommandName
            "CommandName"
            {
                #region Find-Index-Using-Command-Name
                [int]$StackIndex = 0
                :FindCommand foreach($Layer in $CStack)
                {
                    if($Layer.Command -eq $CommandName)
                    {
                        break FindCommand
                    }
                }
                #endregion Find-Index-Using-Command-Name

                break
            }
            #endregion ParameterSet-CommandName
            #region ParameterSet-StackIndex
            "StackIndex" { break }
            #endregion ParameterSet-StackIndex
        }
        #endregion ParameterSet-Specific-Actions
        
        #region Out-Debug
#        
#            -NewLines 2 `
#            -Invocation ($MyInvocation)
        #endregion Out-Debug
        
        $CsEndIndex = ($CStack.Count)
        
        #region Out-Debug
#        
#            ($StackIndex),`
#            ($CsEndIndex)
#        ) -Invocation ($MyInvocation)
#        
#        
#            ($StackIndex),`
#            ($CsEndIndex)
#        ) -Invocation ($MyInvocation)
#        
#        
#            ($CStack.Count)
#        ) -Invocation ($MyInvocation)
#        
#        
#            ($CsEndIndex - $StackIndex)
#        ) -Invocation ($MyInvocation)
        #endregion Out-Debug
        
        $ReturnVal = @(($CStack)[$StackIndex..$CsEndIndex])
        
        #region Out-Debug
#        
#            ($ReturnVal.Count)
#        ) -Invocation ($MyInvocation)
        #endregion Out-Debug
        
        Write-Output ($ReturnVal)
    }
    #endregion Process {}
}


function New-TimeStamp
{
    param
    (
        #region 00-$Formmat
        [Parameter(Position=00)]
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