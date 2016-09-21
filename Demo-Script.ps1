#region Functions
function Invoke-FirstFunction
{
    Process
    {
        Write-Debug ('This is a debug message from Function #01')
    }
}

function Invoke-SecondFunction
{
    Process
    {
        Write-Debug ('This is a debug message from Function #02')
    }
}

function Invoke-ThirdFunction
{
    Process
    {
        Write-Debug ('This is a debug message from Function #03')
    }
}

function Invoke-ChainStepOne
{
    Invoke-FirstFunction
    Invoke-ChainStepTwo
}

function Invoke-ChainStepTwo
{
    Invoke-SecondFunction
    Invoke-ChainStepThree
}

function Invoke-ChainStepThree
{
    Invoke-ThirdFunction
}

if ((Get-Module | ?{$_.Name -eq 'Write-Module'}))
{
    Remove-Module -Name Write-Module
}
#endregion Functions

#region Execution
$Global:DebugPreference = 'Continue'
$Global:InformationPreference = 'Continue'
$divLine = ('*' * $Host.UI.RawUI.WindowSize.Width)

Write-Host ($divLine)
Write-Host

Write-Information ('An example of standard Write-Debug messages:')
Invoke-ChainStepOne

Write-Host
Write-Host ($divLine)
Write-Host

$modulePath = Join-Path -Path (Split-Path -Path  $PSCommandPath -Parent) -ChildPath 'Write-Module.psd1' -Resolve
Write-Information -MessageData ('Importing Write-Module PoSh Demonstration Module')
Import-Module $modulePath -Global -Force

$Global:DebugPreference = 'Continue'
$Global:InformationPreference = 'Continue'

Write-Information ('An example of augmented Write-Debug output:')
Invoke-ChainStepOne
Write-Host

Write-Host ('The augmented Write-Debug contains additional information in the following order:') -ForegroundColor Green
Write-Host ('Timestamp, Stack Depth, Full path to file containing code, function name (or <scriptblock>), Calling line number. In addition, the console output is indented according to stack depth, making it easier to follow code execution')
Write-Host
Write-Host ('This demo is to show that one can override a common cmdlet such as Write-Debug, thus being able to easily inject functions such as logging into existing code bases. The examples provided take no more arguments than the out-of-box Write-Debug, but provide a vast wealth of additional information. One can see how additional logging could be implemented, such as writing to a database, web service, or file') -ForegroundColor Yellow

Write-Host ($divLine)
#endregion Execution