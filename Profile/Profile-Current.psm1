#region Script-Variables
# For: *-Autologin
$Script:rootRegPath = ([String] ('HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'))
$Script:autoLogonKeyName = ([String] ('AutoAdminLogon'))
$Script:autoLoginEnabledValue = ([Int](1))
$Script:autoLoginDisabledValue = ([Int](1))
$Script:defDomainKeyName = ([String] ('DefaultDomainName'))
$Script:defUsernameKeyName = ([String] ('DefaultUserName'))
$Script:defPasswordKeyName = ([String] ('DefaultPassword'))

# For: Import-ProfileModules
$Script:PersonalModulesFolder = ( [System.IO.DirectoryInfo] ( 'D:\Source\PoSh\Profile' ) )
#endregion Script-Variables

#region Functions
#region *-Autologin
function Disable-Autologin
{
     New-ItemProperty -LiteralPath $rootRegPath -Name $autoLogonKeyName -Value $autoLoginDisabledValue -Force -PropertyType String
}

function Enable-Autologin
{
     [CmdletBinding()]

     param
     (
          [Parameter(Mandatory = $true)]
          [ValidateNotNullOrEmpty()]
          # Default password
          [String]$DefaultPassword
          ,
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          # Default username
          [String]$DefaultUsername = ($env:USERNAME)
          ,
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          # Default domain to login to
          [String]$DefaultLoginDomain = ($env:COMPUTERNAME.ToUpper())
     )

     process
     {
          # Retrieve existing values from the registry (if they exist)
          $autoLoginValue = [Int] (Get-ItemPropertyValue -LiteralPath $rootRegPath -Name $autoLogonKeyName -ErrorAction SilentlyContinue)
          $defDomainValue = [String] (Get-ItemPropertyValue -LiteralPath $rootRegPath -Name $defDomainKeyName -ErrorAction SilentlyContinue)
          $defUsernameValue = [String] (Get-ItemPropertyValue -LiteralPath $rootRegPath -Name $defUsernameKeyName -ErrorAction SilentlyContinue)

          #region Enable-Auto-Login
          if ($autoLoginValue)
          {
               Write-Verbose ('Current {0} value is: {1}' -f $autoLogonKeyName,$autoLoginValue)

               if ($autoLoginValue -ne 1)
               {
                    Write-Verbose ('Updating {0} to {1}' -f $autoLogonKeyName,$autoLoginEnabledValue)
                    Set-ItemProperty -LiteralPath $rootRegPath -Name $autoLogonKeyName -Value $autoLoginEnabledValue
               }
               else
               {
                    Write-Verbose ('{0} already set to {1}. Not modifying' -f $autoLogonKeyName,$autoLoginEnabledValue)
               }
          }
          else
          {
               Write-Verbose ('Current {0} value is: NOT SET' -f $autoLogonKeyName)
               Write-Verbose ('Creating key {0} with value {1}' -f $autoLogonKeyName,$autoLoginEnabledValue)
               New-ItemProperty -LiteralPath $rootRegPath -Name $autoLogonKeyName -Value $autoLoginEnabledValue -PropertyType String -Force | Out-Null
          }
          #endregion Enable-Auto-Login

          #region Set-Default-Username
          if ($defUsernameValue)
          {
               Write-Verbose ('Current {0} value is: {1}' -f $defUsernameKeyName,$defUsernameValue)

               if ($defUsernameValue.ToLower() -ne $DefaultUsername.ToLower())
               {
                    Write-Verbose ('Updating {0} to {1}' -f $defUsernameKeyName,$DefaultUsername)
                    Set-ItemProperty -LiteralPath $rootRegPath -Name $defUsernameKeyName -Value $DefaultUsername
               }
               else
               {
                    Write-Verbose ('{0} already set to {1}. Not modifying' -f $defUsernameKeyName,$DefaultUsername)
               }
          }
          else
          {
               Write-Verbose ('Current {0} value is: NOT SET' -f $defUsernameKeyName)
               Write-Verbose ('Creating key {0} with value {1}' -f $defUsernameKeyName,$DefaultUsername)
               New-ItemProperty -LiteralPath $rootRegPath -Name $defUsernameKeyName -Value $DefaultUsername -PropertyType String -Force | Out-Null
          }
          #endregion Set-Default-Username

          #region Set-Default-Login-Domain
          if ($defDomainValue)
          {
               Write-Verbose ('Current {0} value is: {1}' -f $defDomainKeyName,$defDomainValue)

               if ($defDomainValue -ne $DefaultLoginDomain)
               {
                    Write-Verbose ('Updating {0} to {1}' -f $defDomainKeyName,$DefaultLoginDomain)
                    Set-ItemProperty -LiteralPath $rootRegPath -Name $defDomainKeyName -Value $DefaultLoginDomain
               }
               else
               {
                    Write-Verbose ('{0} already set to {1}. Not modifying' -f $defDomainKeyName,$DefaultLoginDomain)
               }
          }
          else
          {
               Write-Verbose ('Current {0} value is: NOT SET' -f $defDomainKeyName,$defDomainValue)
               Write-Verbose ('Creating key {0} with value {1}' -f $defDomainKeyName,$DefaultLoginDomain)
               New-ItemProperty -LiteralPath $rootRegPath -Name $defDomainKeyName -Value $DefaultLoginDomain -PropertyType String -Force | Out-Null
          }
          #endregion Set-Default-Login-Domain

          #region Set-Default-Password
          Write-Verbose ('Setting default password on account {0}' -f $DefaultUsername)
          Set-ItemProperty -LiteralPath $rootRegPath -Name $defPasswordKeyName -Value $DefaultPassword -Force | Out-Null
          #endregion Set-Default-Password
     }
}

function Get-Autologin
{
     # Retrieve existing values from the registry (if they exist)
     $autoLoginValue = [Int] (Get-ItemPropertyValue -LiteralPath $rootRegPath -Name $autoLogonKeyName -ErrorAction SilentlyContinue)
     $defDomainValue = [String] (Get-ItemPropertyValue -LiteralPath $rootRegPath -Name $defDomainKeyName -ErrorAction SilentlyContinue)
     $defUsernameValue = [String] (Get-ItemPropertyValue -LiteralPath $rootRegPath -Name $defUsernameKeyName -ErrorAction SilentlyContinue)
     $defPasswordValue = [String] (Get-ItemPropertyValue -LiteralPath $rootRegPath -Name $defPasswordKeyName -ErrorAction SilentlyContinue)

     $isEnabled = $false
     if ($autoLoginValue -eq 1)
     {
          $isEnabled = $true
     }

     Write-Output ([PSCustomObject]@{
               'Enabled'                  = $isEnabled
               $autoLogonKeyName          = $autoLoginValue
               $defDomainKeyName          = $defDomainValue
               $defUsernameKeyName        = $defUsernameValue
               $Script:defPasswordKeyName = $defPasswordValue
          })
}

function New-LockWorkstationTask
{
     [CmdletBinding()]

     param
     (
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          # Task Name
          [String]$Name = 'Lock-Workstation'
          ,
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          # Task Path
          [String]$Path = ($env:USERNAME)
     )

     # XML definition of scheduled task
     $schXml = @'
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Date>2016-10-04T17:23:53.6573179</Date>
    <Author>RICKFLIST-LPTP\RickFlist</Author>
    <Description>Locks workstation immediately on login</Description>
    <URI>\Toddle\Lock-Workstation</URI>
  </RegistrationInfo>
  <Triggers>
    <LogonTrigger>
      <Enabled>true</Enabled>
      <UserId>RICKFLIST-LPTP\RickFlist</UserId>
      <Delay>PT30S</Delay>
    </LogonTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>S-1-5-21-726837841-4206799383-1039179817-1001</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>LeastPrivilege</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT72H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>C:\Windows\System32\rundll32.exe</Command>
      <Arguments>user32.dll, LockWorkStation</Arguments>
    </Exec>
  </Actions>
</Task>
'@

     Register-ScheduledTask -TaskName $Name -TaskPath $Path -Xml $schXml -Force
}
#endregion *-Autologin

#region *-*Preference
function Set-DebugPreference
{
     [CmdletBinding()]
     param(
          [ValidateNotNullOrEmpty()]
          [System.Management.Automation.ActionPreference]
          $Preference
     )

     If ($PSBoundParameters['Debug'])
     {
          $DebugPreference = $Preference
     }

     $Global:DebugPreference = $Preference
     $currPref = $Global:DebugPreference
     $Global:DebugPreference = 'Continue'
     Write-Debug ('DebugPreference: {0}' -f $currPref)
     $Global:DebugPreference = $currPref
}

function Set-InformationPreference
{
     [CmdletBinding()]
     param(
          [ValidateNotNullOrEmpty()]
          [System.Management.Automation.ActionPreference]
          $Preference
     )

     $Global:InformationPreference = $Preference
     Write-Information ('InformationPreference: {0}' -f $InformationPreference) -Verbose
}

function Set-VerbosePreference
{
     [CmdletBinding()]
     param(
          [ValidateNotNullOrEmpty()]
          [System.Management.Automation.ActionPreference]
          $Preference
     )

     $Global:VerbosePreference = $Preference
     Write-Verbose ('VerbosePrefernce: {0}' -f $VerbosePreference) -Verbose
}
#endregion *-*Preference

#region ISE-Only
if ($Host.Name -eq 'Windows PowerShell ISE Host')
{
     function Get-ISEShortcut
     {
          [CmdletBinding()]
          param(
               [ValidateNotNullOrEmpty()]
               [ValidateSet('Name','Value')]
               [String]
               $SortBy = 'Value'

          )

          $gps = $psISE.GetType().Assembly
          $rm = New-Object System.Resources.ResourceManager GuiStrings,$gps
          $rm.GetResourceSet((Get-Culture),$True,$True) | Where Value -CMatch "(F\d)|(Shift\+)|(Alt\+)|(Ctrl\+)" | Sort-Object $SortBy | Format-Table -AutoSize -Wrap
     }

     function Reset-IseTab
     {
          <#
        .Synopsis
           Moves open files to a new PowerShell tab
        .Example
           Reset-IseTab �Save { function Prompt {'>'}  }
        #>
          Param(
               [switch]$SaveFiles,
               [ScriptBlock]$InvokeInNewTab
          )

          $Current = $psISE.CurrentPowerShellTab
          $FileList = @()

          $Current.Files | ForEach-Object {
               if ($SaveFiles -and (-not $_.IsSaved))
               {

                    Write-Verbose "Saving $($_.FullPath)"
                    try
                    {
                         $_.Save()
                         $FileList += $_
                    } catch [System.Management.Automation.MethodInvocationException]
                    {
                         # Save will fail saying that you need to SaveAs because the
                         # file doesn't have a path.
                         Write-Verbose "Saving $($_.FullPath) Failed"
                    }
               }
               elseif ($_.IsSaved)
               {
                    $FileList += $_
               }
          }

          $NewTab = $psISE.PowerShellTabs.Add()
          $FileList | ForEach-Object {
               $NewTab.Files.Add($_.FullPath) | Out-Null
               $Current.Files.Remove($_)
          }

          # If a code block was to be sent to the new tab, add it here.
          #  Think module loading or dot-sourcing something to put your environment
          # correct for the specific debug session.
          if ($InvokeInNewTab)
          {

               Write-Verbose "Will call this after the Tab Loads:`n $InvokeInNewTab"

               # Wait for the new tab to be ready to run more commands.
               While (-not $NewTab.CanInvoke)
               {
                    Start-Sleep -Seconds 1
               }

               $NewTab.Invoke($InvokeInNewTab)
          }

          if ($Current.Files.Count -eq 0)
          {
               #Only remove the tab if all of the files closed.
               $psISE.PowerShellTabs.Remove($Current)
          }
     }

     #region ISE-Lines
     #requires -version 2.0
     ## ISE-Lines module v 1.2
     ##############################################################################################################
     ## Provides Line cmdlets for working with ISE
     ## Duplicate-Line - Duplicates current line
     ## Conflate-Line - Conflates current and next line
     ## MoveUp-Line - Moves current line up
     ## MoveDown-Line - Moves current line down
     ## Delete-TrailingBlanks - Deletes trailing blanks in the whole script
     ##
     ## Usage within ISE or Microsoft.PowershellISE_profile.ps1:
     ## Import-Module ISE-Lines.psm1
     ##
     ##############################################################################################################
     ## History:
     ## 1.2 - Minor alterations to work with PowerShell 2.0 RTM and Documentation updates (Hardwick)
     ##       Include Delete-BlankLines function (author Kriszio I believe)
     ## 1.1 - Bugfix and remove line continuation character while joining for Conflate-Line function (Kriszio)
     ## 1.0 - Initial release (Poetter)
     ##############################################################################################################

     ## Duplicate-Line
     ##############################################################################################################
     ## Duplicates current line
     ##############################################################################################################
     function Duplicate-Line
     {
          $editor = $psISE.CurrentFile.Editor
          $caretLine = $editor.CaretLine
          $caretColumn = $editor.CaretColumn
          $text = $editor.Text.Split("`n")
          $line = $text[$caretLine - 1]
          $newText = $text[0..($caretLine - 1)]
          $newText += $line
          $newText += $text[$caretLine..($text.Count - 1)]
          $editor.Text = [String]::Join("`n", $newText)
          $editor.SetCaretPosition($caretLine, $caretColumn)
     }

     ## Conflate-Line
     ##############################################################################################################
     ## Conflates current and next line
     ## v 1.1 fixed bug on last but one line and remove line continuation character while joining
     ##############################################################################################################
     function Conflate-Line
     {
          $editor = $psISE.CurrentFile.Editor
          $caretLine = $editor.CaretLine
          $caretColumn = $editor.CaretColumn
          $text = $editor.Text.Split("`n")
          if ( $caretLine -ne $text.Count )
          {
               $line = $text[$caretLine - 1] + $text[$caretLine] -replace ("(``)?`r", "")
               $newText = @()
               if ( $caretLine -gt 1 )
               {
                    $newText = $text[0..($caretLine - 2)]
               }
               $newText += $line
               if ( $caretLine -ne $text.Count - 1)
               {
                    $newText += $text[($caretLine + 1)..($text.Count - 1)]
               }
               $editor.Text = [String]::Join("`n", $newText)
               $editor.SetCaretPosition($caretLine, $caretColumn)
          }
     }

     ## MoveUp-Line
     ##############################################################################################################
     ## Moves current line up
     ##############################################################################################################
     function MoveUp-Line
     {
          $editor = $psISE.CurrentFile.Editor
          $caretLine = $editor.CaretLine
          if ( $caretLine -ne 1 )
          {
               $caretColumn = $editor.CaretColumn
               $text = $editor.Text.Split("`n")
               $line = $text[$caretLine - 1]
               $lineBefore = $text[$caretLine - 2]
               $newText = @()
               if ( $caretLine -gt 2 )
               {
                    $newText = $text[0..($caretLine - 3)]
               }
               $newText += $line
               $newText += $lineBefore
               if ( $caretLine -ne $text.Count )
               {
                    $newText += $text[$caretLine..($text.Count - 1)]
               }
               $editor.Text = [String]::Join("`n", $newText)
               $editor.SetCaretPosition($caretLine - 1, $caretColumn)
          }
     }

     ## MoveDown-Line
     ##############################################################################################################
     ## Moves current line down
     ##############################################################################################################
     function MoveDown-Line
     {
          $editor = $psISE.CurrentFile.Editor
          $caretLine = $editor.CaretLine
          $caretColumn = $editor.CaretColumn
          $text = $editor.Text.Split("`n")
          if ( $caretLine -ne $text.Count )
          {
               $line = $text[$caretLine - 1]
               $lineAfter = $text[$caretLine]
               $newText = @()
               if ( $caretLine -ne 1 )
               {
                    $newText = $text[0..($caretLine - 2)]
               }
               $newText += $lineAfter
               $newText += $line
               if ( $caretLine -lt $text.Count - 1 )
               {
                    $newText += $text[($caretLine + 1)..($text.Count - 1)]
               }
               $editor.Text = [String]::Join("`n", $newText)
               $editor.SetCaretPosition($caretLine + 1, $caretColumn)
          }
     }

     ## Delete-TrailingBlanks
     ##############################################################################################################
     ## Deletes trailing blanks in the whole script
     ##############################################################################################################
     function Delete-TrailingBlanks
     {
          $editor = $psISE.CurrentFile.Editor
          $caretLine = $editor.CaretLine
          $newText = @()
          foreach ( $line in $editor.Text.Split("`n") )
          {
               $newText += $line -replace ("\s+$", "")
          }
          $editor.Text = [String]::Join("`n", $newText)
          $editor.SetCaretPosition($caretLine, 1)
     }

     ## Delete-BlankLines
     ##############################################################################################################
     ## Deletes blank lines from the selected text
     ##############################################################################################################
     function Delete-BlankLines
     {
          # Code from the ISECream Archive (http://psisecream.codeplex.com/), originally named Remove-IseEmptyLines

          # Todo it would be nice to keep the caretposition, but I found no easy way
          # of course you can split the string into an array of lines
          $editor = $psISE.CurrentFile.Editor
          #$caretLine = $editor.CaretLine
          if ($editor.SelectedText)
          {
               Microsoft.PowerShell.Utility\Write-Host 'selected'
               $editor.InsertText(($editor.SelectedText -replace '(?m)\s*$', ''))
          }
          else
          {
               $editor.Text = $editor.Text -replace '(?m)\s*$', ''
          }
          $editor.SetCaretPosition(1, 1)
     }

     ##############################################################################################################
     ## Inserts a submenu Lines to ISE's Custum Menu
     ## Inserts command Duplicate Line to submenu Lines
     ## Inserts command Conflate Line Selected to submenu Lines
     ## Inserts command Move Up Line to submenu Lines
     ## Inserts command Move Down Line to submenu Lines
     ## Inserts command Delete Trailing Blanks to submenu Lines
     ## Inserts command Delete Blank Lines to submenu Lines
     ##############################################################################################################
     if (-not( $psISE.CurrentPowerShellTab.AddOnsMenu.Submenus | where { $_.DisplayName -eq "Lines" } ) )
     {
          $linesMenu = $psISE.CurrentPowerShellTab.AddOnsMenu.SubMenus.Add("_Lines",$null,$null)
          $null = $linesMenu.Submenus.Add("Duplicate Line", {Duplicate-Line}, "Ctrl+Alt+D")
          $null = $linesMenu.Submenus.Add("Conflate Line", {Conflate-Line}, "Ctrl+Alt+J")
          $null = $linesMenu.Submenus.Add("Move Up Line", {MoveUp-Line}, "Ctrl+Shift+Up")
          $null = $linesMenu.Submenus.Add("Move Down Line", {MoveDown-Line}, "Ctrl+Shift+Down")
          $null = $linesMenu.Submenus.Add("Delete Trailing Blanks", {Delete-TrailingBlanks}, "Ctrl+Shift+Del")
          $null = $linesMenu.Submenus.Add("Delete Blank Lines", {Delete-BlankLines}, "Ctrl+Shift+Ins")
     }

     # If you are using IsePack (http://code.msdn.microsoft.com/PowerShellPack) and IseCream (http://psisecream.codeplex.com/),
     # you can use this code to add your menu items. The added benefits are that you can specify the order of the menu items and
     # if the shortcut already exists it will add the menu item without the shortcut instead of failing as the default does.
     # Add-IseMenu -Name "Lines" @{
     #    "Duplicate Line"  = {Duplicate-Line}| Add-Member NoteProperty order  1 -PassThru | Add-Member NoteProperty ShortcutKey "Ctrl+Alt+D" -PassThru
     #    "Conflate Line" = {Conflate-Line}| Add-Member NoteProperty order  2 -PassThru | Add-Member NoteProperty ShortcutKey "Ctrl+Alt+J" -PassThru
     #    "Move Up Line" = {MoveUp-Line}| Add-Member NoteProperty order  3 -PassThru | Add-Member NoteProperty ShortcutKey "Ctrl+Shift+Up" -PassThru
     #    "Move Down Line"   = {MoveDown-Line}| Add-Member NoteProperty order  4 -PassThru | Add-Member NoteProperty ShortcutKey "Ctrl+Shift+Down" -PassThru
     #    "Delete Trailing Blanks" = {Delete-TrailingBlanks}| Add-Member NoteProperty order  5 -PassThru | Add-Member NoteProperty ShortcutKey "Ctrl+Shift+Del" -PassThru
     #    "Delete Blank Lines" = {Delete-BlankLines} | Add-Member NoteProperty order  6 -PassThru | Add-Member NoteProperty ShortcutKey "Ctrl+Shift+End" -PassThru
     #    }
     #endregion ISE-Lines

     #region ISE-Comments
     #requires -version 2.0
     ## ISE-Comments module v 1.1
     ##############################################################################################################
     ## Provides Comment cmdlets for working with ISE
     ## ConvertTo-BlockComment - Comments out selected text with <# before and #> after
     ## ConvertTo-BlockUncomment - Removes <# before and #> after selected text
     ## ConvertTo-Comment - Comments out selected text with a leeding # on every line
     ## ConvertTo-Uncomment - Removes leeding # on every line of selected text
     ##
     ## Usage within ISE or Microsoft.PowershellISE_profile.ps1:
     ## Import-Module ISE-Comments.psm1
     ##
     ## Note: The IsePack, a part of the PowerShellPack, also contains a "Toggle Comments" command,
     ##       but it does not support Block Comments
     ##       http://code.msdn.microsoft.com/PowerShellPack
     ##
     ##############################################################################################################
     ## History:
     ## 1.1 - Minor alterations to work with PowerShell 2.0 RTM and Documentation updates (Hardwick)
     ## 1.0 - Initial release (Poetter)
     ##############################################################################################################


     ## ConvertTo-BlockComment
     ##############################################################################################################
     ## Comments out selected text with <# before and #> after
     ## This code was originaly designed by Jeffrey Snover and was taken from the Windows PowerShell Blog.
     ## The original function was named ConvertTo-Comment but as it comments out a block I renamed it.
     ##############################################################################################################
     function ConvertTo-BlockComment
     {
          $editor = $psISE.CurrentFile.Editor
          $CommentedText = "<#`n" + $editor.SelectedText + "#>"
          # INSERTING overwrites the SELECTED text
          $editor.InsertText($CommentedText)
     }

     ## ConvertTo-BlockUncomment
     ##############################################################################################################
     ## Removes <# before and #> after selected text
     ##############################################################################################################
     function ConvertTo-BlockUncomment
     {
          $editor = $psISE.CurrentFile.Editor
          $CommentedText = $editor.SelectedText -replace ("^<#`n", "")
          $CommentedText = $CommentedText -replace ("#>$", "")
          # INSERTING overwrites the SELECTED text
          $editor.InsertText($CommentedText)
     }

     ## ConvertTo-Comment
     ##############################################################################################################
     ## Comments out selected text with a leeding # on every line
     ##############################################################################################################
     function ConvertTo-Comment
     {
          $editor = $psISE.CurrentFile.Editor
          $CommentedText = $editor.SelectedText.Split("`n")
          # INSERTING overwrites the SELECTED text
          $editor.InsertText( "#" + ( [String]::Join("`n#", $CommentedText)))
     }

     ## ConvertTo-Uncomment
     ##############################################################################################################
     ## Comments out selected text with <# before and #> after
     ##############################################################################################################
     function ConvertTo-Uncomment
     {
          $editor = $psISE.CurrentFile.Editor
          $CommentedText = $editor.SelectedText.Split("`n") -replace ( "^#", "" )
          # INSERTING overwrites the SELECTED text
          $editor.InsertText( [String]::Join("`n", $CommentedText))
     }

     ##############################################################################################################
     ## Inserts a submenu Comments to ISE's Custum Menu
     ## Inserts command Block Comment Selected to submenu Comments
     ## Inserts command Block Uncomment Selected to submenu Comments
     ## Inserts command Comment Selected to submenu Comments
     ## Inserts command Uncomment Selected to submenu Comments
     ##############################################################################################################
     if (-not( $psISE.CurrentPowerShellTab.AddOnsMenu.Submenus | where { $_.DisplayName -eq "Comments" } ) )
     {
          $commentsMenu = $psISE.CurrentPowerShellTab.AddOnsMenu.SubMenus.Add("_Comments",$null,$null)
          $null = $commentsMenu.Submenus.Add("Block Comment Selected", {ConvertTo-BlockComment}, "Ctrl+SHIFT+B")
          $null = $commentsMenu.Submenus.Add("Block Uncomment Selected", {ConvertTo-BlockUncomment}, "Ctrl+Alt+B")
          $null = $commentsMenu.Submenus.Add("Comment Selected", {ConvertTo-Comment}, "Ctrl+SHIFT+C")
          $null = $commentsMenu.Submenus.Add("Uncomment Selected", {ConvertTo-Uncomment}, "Ctrl+Alt+C")
     }

     # If you are using IsePack (http://code.msdn.microsoft.com/PowerShellPack) and IseCream (http://psisecream.codeplex.com/),
     # you can use this code to add your menu items. The added benefits are that you can specify the order of the menu items and
     # if the shortcut already exists it will add the menu item without the shortcut instead of failing as the default does.
     # Add-IseMenu -Name "Comments" @{
     #    "Block Comment Selected"  = {ConvertTo-BlockComment}| Add-Member NoteProperty order  1 -PassThru  | Add-Member NoteProperty ShortcutKey "Ctrl+SHIFT+B" -PassThru
     #    "Block Uncomment Selected" = {ConvertTo-BlockUncomment}| Add-Member NoteProperty order  2 -PassThru  | Add-Member NoteProperty ShortcutKey "Ctrl+Alt+B" -PassThru
     #    "Comment Selected" = {ConvertTo-Comment}| Add-Member NoteProperty order  3 -PassThru  | Add-Member NoteProperty ShortcutKey "Ctrl+SHIFT+C" -PassThru
     #    "Uncomment Selected"  = {ConvertTo-Uncomment}| Add-Member NoteProperty order  4 -PassThru  | Add-Member NoteProperty ShortcutKey "Ctrl+Alt+C" -PassThru
     #    }
     #endregion ISE-Comments

     # ISE Steroids
     if ( Get-Module -Name 'ISESteroids' -ListAvailable )
     {
          Import-Module -Name 'ISESteroids' -Force -Global
     }
}
#endregion ISE-Only

#region File-System
function Export-DirectoryAcl
{
     [CmdletBinding()]
     [OutputType()]

     param
     (
          [Parameter(Mandatory = $true)]
          [ValidateNotNullOrEmpty()]
          [System.IO.DirectoryInfo]
          # Folder structure to interrogate
          $LiteralPath
          ,
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          [System.IO.FileInfo]
          # File to write permissions to
          $OutputFile = (Join-Path -Path $env:SystemDrive -ChildPath ('ACL-[{0}]-[{1}].csv' -f $LiteralPath.Name,(Get-Date -Format 'yyyyMMdd-HHmmss')))
     )

     process
     {
          Write-Debug ('Output File Absolute Path: {0}' -f $OutputFile.FullName)

          Write-Debug ('Getting ACLs on folder ''{0}''' -f $LiteralPath.FullName)
          (Get-Acl -LiteralPath $LiteralPath.FullName | Select-Object @{N = "Path"; E = {Convert-Path $PSItem.Path}} -ExpandProperty Access) | Export-Csv -LiteralPath $OutputFile.FullName -NoTypeInformation -Force

          $subFolders = Get-ChildItem -Path $LiteralPath.FullName -Recurse -Directory
          foreach ($fldr in $subFolders)
          {
               Write-Debug ('Getting ACLs on folder ''{0}''' -f $fldr.FullName)
               $fldr | `
                    Get-Acl | `
                    Where-Object {$PSItem.IsInherited -eq $false} | `
                    Select-Object @{N = "Path"; E = {Convert-Path $PSItem.Path}} -ExpandProperty Access | `
                    Export-Csv -LiteralPath $OutputFile.FullName -NoTypeInformation -Append
          }
<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER Path
Parameter description

.PARAMETER Include
Parameter description

.PARAMETER Exclude
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>   }
}

function Export-ShareAcl
{
     [CmdletBinding()]
     [OutputType()]

     param
     (
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          [System.IO.FileInfo]
          # File to write permissions to
          $OutputFile = (Join-Path -Path $env:SystemDrive -ChildPath ('Share-[{0}]-[{1}].csv' -f $env:COMPUTERNAME.ToUpper(),(Get-Date -Format 'yyyyMMdd-HHmmss')))
     )

     process
     {
          Import-Module SmbShare -Force -ErrorAction Stop
          $allShares = Get-SmbShare | Where-Object {$PSItem.Special -eq $false}

          foreach ($share in $allShares)
          {
               Write-Debug ('Current Share: ''{0}'' (Local Path: ''{1}'')' -f $share.Name,$share.Path)
               $authRules = $share.PresetPathAcl.GetAccessRules($true,$true,[System.Security.Principal.NTAccount])
               $accessString = New-Object System.Text.StringBuilder
               foreach ($rule in $authRules)
               {
                    $tempString = ('{0};{1};{2}' -f $rule.IdentityReference,$rule.AccessControlType,$rule.FileSystemRights)

                    if ($accessString.Length -eq 0)
                    {
                         $accessString.Append($tempString) | Out-Null
                    }
                    else
                    {
                         $accessString.Append((':{0}' -f $tempString)) | Out-Null
                    }
               }

               $retVal = [PSCustomObject] @{
                    Name       = $share.Name
                    LocalPath  = $share.Path
                    Access     = $accessString
                    SddlString = $share.SecurityDescriptor
               }

               $retVal | Export-Csv -LiteralPath $OutputFile.FullName -NoTypeInformation -Append
          }
     }
}

function Measure-Folder
{
     <#
      .SYNOPSIS
        Gets folder sizes using COM and by default with a fallback to robocopy.exe, with the
        logging only option, which makes it not actually copy or move files, but just list them, and
        the end summary result is parsed to extract the relevant data.

        There is a -ComOnly parameter for using only COM, and a -RoboOnly parameter for using only
        robocopy.exe with the logging only option.

        The robocopy output also gives a count of files and folders, unlike the COM method output.
        The default number of threads used by robocopy is 8, but I set it to 16 since this cut the
        run time down to almost half in some cases during my testing. You can specify a number of
        threads between 1-128 with the parameter -RoboThreadCount.

        Both of these approaches are apparently much faster than .NET and Get-ChildItem in PowerShell.

        The properties of the objects will be different based on which method is used, but
        the "TotalBytes" property is always populated if the directory size was successfully
        retrieved. Otherwise you should get a warning (and the sizes will be zero).

        Online "blog" documentation: http://www.powershelladmin.com/wiki/Get_Folder_Size_with_PowerShell,_Blazingly_Fast

        BSD 3-clause license. http://www.opensource.org/licenses/BSD-3-Clause

        Copyright (C) 2015, Joakim Svendsen
        All rights reserved.
        Svendsen Tech.

      .PARAMETER Path
        Path or paths to measure size of.

      .PARAMETER Precision
        Number of digits after decimal point in rounded numbers.

      .PARAMETER RoboOnly
        Do not use COM, only robocopy, for always getting full details.

      .PARAMETER ComOnly
        Never fall back to robocopy, only use COM.

      .PARAMETER RoboThreadCount
        Number of threads used when falling back to robocopy, or with -RoboOnly.
        Default: 16 (gave the fastest results during my testing).

      .EXAMPLE
        . .\Get-FolderSize.ps1
        PS C:\> 'C:\Windows', 'E:\temp' | Get-FolderSize

      .EXAMPLE
        Get-FolderSize -Path Z:\Database -Precision 2

      .EXAMPLE
        Get-FolderSize -Path Z:\Database -RoboOnly -RoboThreadCount 64

      .EXAMPLE
        Get-FolderSize -Path Z:\Database -RoboOnly

      .EXAMPLE
        Get-FolderSize A:\FullHDFloppyMovies -ComOnly

    #>

     [CmdletBinding()]
     param(
          [Parameter(Mandatory = $true,
               ValueFromPipeline = $true,
               ValueFromPipelineByPropertyName = $true)]
          [string[]] $Path,
          [int] $Precision = 4,
          [switch] $RoboOnly,
          [switch] $ComOnly,
          [ValidateRange(1, 128)] [byte] $RoboThreadCount = 16)

     begin
     {
          if ($RoboOnly -and $ComOnly)
          {
               Write-Error -Message "You can't use both -ComOnly and -RoboOnly. Default is COM with a fallback to robocopy." -ErrorAction Stop
          }
          if (-not $RoboOnly)
          {
               $FSO = New-Object -ComObject Scripting.FileSystemObject -ErrorAction Stop
          }

          function Get-RoboFolderSizeInternal
          {
               [CmdletBinding()]
               param(
                    # Paths to report size, file count, dir count, etc. for.
                    [string[]] $Path,
                    [int] $Precision = 4)

               begin
               {
                    if (-not (Get-Command -Name robocopy -ErrorAction SilentlyContinue))
                    {
                         Write-Warning -Message "Fallback to robocopy failed because robocopy.exe could not be found. Path '$p'. $([datetime]::Now)."
                         return
                    }
               }

               process
               {
                    foreach ($p in $Path)
                    {
                         Write-Verbose -Message "Processing path '$p' with Get-RoboFolderSizeInternal. $([datetime]::Now)."
                         $RoboCopyArgs = @("/L","/S","/NJH","/BYTES","/FP","/NC","/NDL","/TS","/XJ","/R:0","/W:0","/MT:$RoboThreadCount")
                         [datetime] $StartedTime = [datetime]::Now
                         [string] $Summary = robocopy $p NULL $RoboCopyArgs | Select-Object -Last 8
                         [datetime] $EndedTime = [datetime]::Now
                         [regex] $HeaderRegex = '\s+Total\s*Copied\s+Skipped\s+Mismatch\s+FAILED\s+Extras'
                         [regex] $DirLineRegex = 'Dirs\s*:\s*(?<DirCount>\d+)(?:\s*\d+){3}\s*(?<DirFailed>\d+)\s*\d+'
                         [regex] $FileLineRegex = 'Files\s*:\s*(?<FileCount>\d+)(?:\s*\d+){3}\s*(?<FileFailed>\d+)\s*\d+'
                         [regex] $BytesLineRegex = 'Bytes\s*:\s*(?<ByteCount>\d+)(?:\s*\d+){3}\s*(?<BytesFailed>\d+)\s*\d+'
                         [regex] $TimeLineRegex = 'Times\s*:\s*(?<TimeElapsed>\d+).*'
                         [regex] $EndedLineRegex = 'Ended\s*:\s*(?<EndedTime>.+)'
                         if ($Summary -match "$HeaderRegex\s+$DirLineRegex\s+$FileLineRegex\s+$BytesLineRegex\s+$TimeLineRegex\s+$EndedLineRegex")
                         {
                              $TimeElapsed = [math]::Round([decimal] ($EndedTime - $StartedTime).TotalSeconds, $Precision)
                              New-Object PSObject -Property @{
                                   Path        = $p
                                   TotalBytes  = [decimal] $Matches['ByteCount']
                                   TotalMBytes = [math]::Round(([decimal] $Matches['ByteCount'] / 1MB), $Precision)
                                   TotalGBytes = [math]::Round(([decimal] $Matches['ByteCount'] / 1GB), $Precision)
                                   BytesFailed = [decimal] $Matches['BytesFailed']
                                   DirCount    = [decimal] $Matches['DirCount']
                                   FileCount   = [decimal] $Matches['FileCount']
                                   DirFailed   = [decimal] $Matches['DirFailed']
                                   FileFailed  = [decimal] $Matches['FileFailed']
                                   TimeElapsed = $TimeElapsed
                                   StartedTime = $StartedTime
                                   EndedTime   = $EndedTime

                              } | Select Path, TotalBytes, TotalMBytes, TotalGBytes, DirCount, FileCount, DirFailed, FileFailed, TimeElapsed, StartedTime, EndedTime
                         }
                         else
                         {
                              Write-Warning -Message "Path '$p' output from robocopy was not in an expected format."
                         }
                    }
               }
          }
     }

     process
     {
          foreach ($p in $Path)
          {
               Write-Verbose -Message "Processing path '$p'. $([datetime]::Now)."

               if (-not (Test-Path -Path $p -PathType Container))
               {
                    Write-Warning -Message "$p does not exist or is a file and not a directory. Skipping."
                    continue
               }

               # We know we can't have -ComOnly here if we have -RoboOnly.
               if ($RoboOnly)
               {
                    Get-RoboFolderSizeInternal -Path $p -Precision $Precision
                    continue
               }

               $ErrorActionPreference = 'Stop'
               try
               {
                    $StartFSOTime = [datetime]::Now
                    $TotalBytes = $FSO.GetFolder($p).Size
                    $EndFSOTime = [datetime]::Now
                    if ($TotalBytes -eq $null)
                    {
                         if (-not $ComOnly)
                         {
                              Get-RoboFolderSizeInternal -Path $p -Precision $Precision
                              continue
                         }
                         else
                         {
                              Write-Warning -Message "Failed to retrieve folder size for path '$p': $($Error[0].Exception.Message)."
                         }
                    }
               }
               catch
               {
                    if ($_.Exception.Message -like '*PERMISSION*DENIED*')
                    {
                         if (-not $ComOnly)
                         {
                              Write-Verbose "Caught a permission denied. Trying robocopy."
                              Get-RoboFolderSizeInternal -Path $p -Precision $Precision
                              continue
                         }
                         else
                         {
                              Write-Warning "Failed to process path '$p' due to a permission denied error: $($_.Exception.Message)"
                         }
                    }
                    Write-Warning -Message "Encountered an error while processing path '$p': $_"
                    continue
               }

               $ErrorActionPreference = 'Continue'

               New-Object PSObject -Property @{
                    Path        = $p
                    TotalBytes  = [decimal] $TotalBytes
                    TotalMBytes = [math]::Round(([decimal] $TotalBytes / 1MB), $Precision)
                    TotalGBytes = [math]::Round(([decimal] $TotalBytes / 1GB), $Precision)
                    BytesFailed = $null
                    DirCount    = (@(Get-ChildItem -Path $p -Directory -Recurse).Count)
                    FileCount   = $null
                    DirFailed   = $null
                    FileFailed  = $null
                    TimeElapsed = [math]::Round(([decimal] ($EndFSOTime - $StartFSOTime).TotalSeconds), $Precision)
                    StartedTime = $StartFSOTime
                    EndedTime   = $EndFSOTime
               } | Select Path, TotalBytes, TotalMBytes, TotalGBytes, DirCount, FileCount, DirFailed, FileFailed, TimeElapsed, StartedTime, EndedTime
          }
     }

     end
     {
          if (-not $RoboOnly)
          {
               [void][System.Runtime.Interopservices.Marshal]::ReleaseComObject($FSO)
          }
          [gc]::Collect()
          [gc]::WaitForPendingFinalizers()
     }
}

function New-Folder
{
     [CmdletBinding(DefaultParameterSetName = 'FixedLength',ConfirmImpact = 'None')]
     [OutputType([String])]

     param
     (
          [Parameter(Mandatory = $true)]
          [ValidateNotNullOrEmpty()]
          # Path of folder to create
          [String] $LiteralPath
     )

     process
     {
          if ($LiteralPath.StartsWith('\\') -or ($LiteralPath.Contains(':')))
          {
               $di = ([System.IO.DirectoryInfo] $LiteralPath)
          }
          else
          {
               #$di = ([System.IO.DirectoryInfo] (Join-Path -Path $PWD.ProviderPath -ChildPath $LiteralPath))
               $di = ([System.IO.DirectoryInfo] ('{0}\{1}' -f $PWD.ProviderPath, $LiteralPath))
          }

          try
          {
               $di.Create()
          }
          catch [Exception]
          {
               Write-Error ('Error creating {0}' -f $di.FullName) -Exception $PSItem
          }
     }
}

function Resolve-FullPath
{
     <#
      .SYNOPSIS
      Converts a relative path to an absolute path.

      .DESCRIPTION
      Unlike `Resolve-Path`, this function does not check whether the path exists.  It just converts relative paths to absolute paths.

      Unrooted paths (e.g. `..\..\See\I\Do\Not\Have\A\Root`) are first joined with the current directory (as returned by `Get-Location`).

      .EXAMPLE
      Resolve-FullPath -Path 'C:\Projects\Carbon\Test\..\Carbon\FileSystem.ps1'

      Returns `C:\Projects\Carbon\Carbon\FileSystem.ps1`.

      .EXAMPLE
      Resolve-FullPath -Path 'C:\Projects\Carbon\..\I\Do\Not\Exist'

      Returns `C:\Projects\I\Do\Not\Exist`.

      .EXAMPLE
      Resolve-FullPath -Path ..\..\Foo\..\Bar

      Because the `Path` isn't rooted, joins `Path` with the current directory (as returned by `Get-Location`), and returns the full path.  If the current directory is `C:\Projects\Carbon`, returns `C:\Bar`.
    #>
     [CmdletBinding()]
     [OutputType([System.IO.DirectoryInfo],[System.IO.FileInfo])]

     param(
          [Parameter(Mandatory = $true)]
          [string]
          # The path to resolve.  Must be rooted, i.e. have a drive at the beginning.
          $Path
     )

     Set-StrictMode -Version 'Latest'

     if ( -not ( [System.IO.Path]::IsPathRooted($Path) ) )
     {
          $Path = Join-Path -Path (Get-Location) -ChildPath $Path
     }

     Write-Output (Get-Item -Path  ([IO.Path]::GetFullPath($Path)))
}

#endregion File-System

#region Misc-Commands
function Measure-Latency
{
     [CmdletBinding()]
     [OutputType([LatencyResult])]

     param
     (
          [Parameter(Mandatory = $true)]
          [ValidateNotNullOrEmpty()]
          [String]
          # DNSor IP to measure latency to
          $ComputerName
          ,
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          [Int]
          # Number of times to ping destination
          $Count = 5
     )

     process
     {
          Class LatencyResult
          {
               [String]$Source = [String]::Empty
               [String]$Destination = [String]::Empty
               [System.Net.IPAddress] $IpAddress
               [TimeSpan]$Time
               [DateTime]$StartTime
               [DateTime]$EndTime
          }

          for ($iteraton = 0; $iteraton -lt $Count;$iteraton++)
          {
               $startTime = Get-Date
               $pingResult = Test-Connection -ComputerName $ComputerName -Count 1
               $endTime = Get-Date

               $ts = (New-Object -TypeName System.TimeSpan -ArgumentList @(0,0,0,0,$pingResult.ResponseTime))

               $returnValue = New-Object LatencyResult

               $returnValue.Source = ($pingResult.PSComputerName)
               $returnValue.Destination = ($pingResult.Address)
               $returnValue.IpAddress = ($pingResult.ProtocolAddress)
               $returnValue.Time = ($ts)
               $returnValue.StartTime = ($startTime)
               $returnValue.EndTime = ($endTime)

               Write-Output $returnValue
          }
     }
}

function New-RandomPassword
{
     <#
      .Synopsis
       Generates one or more complex passwords designed to fulfill the requirements for Active Directory
      .DESCRIPTION
       Generates one or more complex passwords designed to fulfill the requirements for Active Directory
      .EXAMPLE
       New-SWRandomPassword
       C&3SX6Kn

       Will generate one password with a length between 8  and 12 chars.
      .EXAMPLE
       New-SWRandomPassword -MinPasswordLength 8 -MaxPasswordLength 12 -Count 4
       7d&5cnaB
       !Bh776T"Fw
       9"C"RxKcY
       %mtM7#9LQ9h

       Will generate four passwords, each with a length of between 8 and 12 chars.
      .EXAMPLE
       New-SWRandomPassword -InputStrings abc, ABC, 123 -PasswordLength 4
       3ABa

       Generates a password with a length of 4 containing atleast one char from each InputString
      .EXAMPLE
       New-SWRandomPassword -InputStrings abc, ABC, 123 -PasswordLength 4 -FirstChar abcdefghijkmnpqrstuvwxyzABCEFGHJKLMNPQRSTUVWXYZ
       3ABa

       Generates a password with a length of 4 containing atleast one char from each InputString that will start with a letter from
       the string specified with the parameter FirstChar
      .OUTPUTS
       [String]
      .NOTES
       Written by Simon W�hlin, blog.simonw.se
       I take no responsibility for any issues caused by this script.
      .FUNCTIONALITY
       Generates random passwords
      .LINK
       http://blog.simonw.se/powershell-generating-random-password-for-active-directory/

    #>
     [CmdletBinding(DefaultParameterSetName = 'FixedLength',ConfirmImpact = 'None')]
     [OutputType([String])]
     Param
     (
          # Specifies minimum password length
          [Parameter(Mandatory = $false,
               ParameterSetName = 'RandomLength')]
          [ValidateScript( {$_ -gt 0})]
          [Alias('Min')]
          [int]$MinPasswordLength = 15,

          # Specifies maximum password length
          [Parameter(Mandatory = $false,
               ParameterSetName = 'RandomLength')]
          [ValidateScript( {
                    if ($_ -ge $MinPasswordLength)
                    {
                         $true
                    }
                    else
                    {
                         Throw 'Max value cannot be lesser than min value.'
                    }})]
          [Alias('Max')]
          [int]$MaxPasswordLength = 25,

          # Specifies a fixed password length
          [Parameter(Mandatory = $false,
               ParameterSetName = 'FixedLength')]
          [ValidateRange(1,2147483647)]
          [int]$PasswordLength = 15,

          # Specifies an array of strings containing charactergroups from which the password will be generated.
          # At least one char from each group (string) will be used.
          [String[]]$InputStrings = @('abcdefghijkmnpqrstuvwxyz', 'ABCEFGHJKLMNPQRSTUVWXYZ', '123456789', '!#%&@'),

          # Specifies a string containing a character group from which the first character in the password will be generated.
          # Useful for systems which requires first char in password to be alphabetic.
          [String] $FirstChar,

          # Specifies number of passwords to generate.
          [ValidateRange(1,2147483647)]
          [int]$Count = 1
     )

     Begin
     {
          Function Get-Seed
          {
               # Generate a seed for randomization
               $RandomBytes = New-Object -TypeName 'System.Byte[]' 4
               $Random = New-Object -TypeName 'System.Security.Cryptography.RNGCryptoServiceProvider'
               $Random.GetBytes($RandomBytes)
               [BitConverter]::ToUInt32($RandomBytes, 0)
          }
     }

     Process
     {
          For ($iteration = 1;$iteration -le $Count; $iteration++)
          {
               $Password = @{}
               # Create char arrays containing groups of possible chars
               [char[][]]$CharGroups = $InputStrings

               # Create char array containing all chars
               $AllChars = $CharGroups | ForEach-Object {[Char[]]$_}

               # Set password length
               if ($PSCmdlet.ParameterSetName -eq 'RandomLength')
               {
                    if ($MinPasswordLength -eq $MaxPasswordLength)
                    {
                         # If password length is set, use set length
                         $PasswordLength = $MinPasswordLength
                    }
                    else
                    {
                         # Otherwise randomize password length
                         $PasswordLength = ((Get-Seed) % ($MaxPasswordLength + 1 - $MinPasswordLength)) + $MinPasswordLength
                    }
               }

               # If FirstChar is defined, randomize first char in password from that string.
               if ($PSBoundParameters.ContainsKey('FirstChar'))
               {
                    $Password.Add(0,$FirstChar[((Get-Seed) % $FirstChar.Length)])
               }
               # Randomize one char from each group
               Foreach ($Group in $CharGroups)
               {
                    if ($Password.Count -lt $PasswordLength)
                    {
                         $Index = Get-Seed
                         While ($Password.ContainsKey($Index))
                         {
                              $Index = Get-Seed
                         }
                         $Password.Add($Index,$Group[((Get-Seed) % $Group.Count)])
                    }
               }

               # Fill out with chars from $AllChars
               for ($i = $Password.Count;$i -lt $PasswordLength;$i++)
               {
                    $Index = Get-Seed
                    While ($Password.ContainsKey($Index))
                    {
                         $Index = Get-Seed
                    }
                    $Password.Add($Index,$AllChars[((Get-Seed) % $AllChars.Count)])
               }
               Write-Output -InputObject $( -join ($Password.GetEnumerator() | Sort-Object -Property Name | Select-Object -ExpandProperty Value))
          }
     }
}

function Resolve-PoshError
{
     <#
          .SYNOPSIS
          Displays detailed information about an error and its context
     #>

     [CmdletBinding()]
     param
     (
          ## The error to resolve
          $ErrorRecord = ($error[0])
     )

     Set-StrictMode -Off

     $bannerColor = [System.ConsoleColor]::Gray
     $headerColor = [System.ConsoleColor]::Green
     $lineWidth = ($Host.UI.RawUI.BufferSize.Width - 1)

     Microsoft.PowerShell.Utility\Write-Host
     Microsoft.PowerShell.Utility\Write-Host ('-' * $lineWidth) -ForegroundColor $bannerColor
     Microsoft.PowerShell.Utility\Write-Host ('Error Details ($error[0] | Format-List * -Force)') -ForegroundColor $headerColor
     Microsoft.PowerShell.Utility\Write-Host ('-' * $lineWidth) -ForegroundColor $bannerColor

     ($errorRecord | Format-List * -Force | Out-String).Trim("`r`n")

     Microsoft.PowerShell.Utility\Write-Host
     Microsoft.PowerShell.Utility\Write-Host ('-' * $lineWidth) -ForegroundColor $bannerColor
     Microsoft.PowerShell.Utility\Write-Host ('InvocationInfo ($error[0].InvocationInfo | Format-List *)') -ForegroundColor $headerColor
     Microsoft.PowerShell.Utility\Write-Host ('-' * $lineWidth) -ForegroundColor $bannerColor

     ($errorRecord.InvocationInfo | Format-List * | Out-String).Trim("`r`n")

     if ($ErrorRecord.TargetObject)
     {
          Microsoft.PowerShell.Utility\Write-Host
          Microsoft.PowerShell.Utility\Write-Host ('-' * $lineWidth) -ForegroundColor $bannerColor
          Microsoft.PowerShell.Utility\Write-Host ('TargetObject Details ($error[0].TargetObject | Format-List *)') -ForegroundColor $headerColor
          Microsoft.PowerShell.Utility\Write-Host ('-' * $lineWidth) -ForegroundColor $bannerColor
          ($errorRecord.TargetObject | Format-List * | Out-String).Trim("`r`n")
     }

     Microsoft.PowerShell.Utility\Write-Host
     Microsoft.PowerShell.Utility\Write-Host ('-' * $lineWidth) -ForegroundColor $bannerColor
     Microsoft.PowerShell.Utility\Write-Host ('Exception Details ($error[0].Exception | Format-List * -Force)') -ForegroundColor $headerColor
     Microsoft.PowerShell.Utility\Write-Host ('-' * $lineWidth) -ForegroundColor $bannerColor

     $exception = $errorRecord.Exception

     for ($i = 1; $exception; $i++, ($exception = $exception.InnerException))
     {
          $tabs = ("----" * ($i + 1))
          Microsoft.PowerShell.Utility\Write-Host ('{0:00}) Exception: {1}' -f $i,$exception.GetType().FullName) -ForegroundColor Yellow
          ($exception | Format-List * -Force | Out-String).Trim("`r`n")
          Microsoft.PowerShell.Utility\Write-Host
     }
}

function Restart-PowerShellAsAdmin
{
     [CmdletBinding()]
     [OutputType()]

     param ()

     process
     {
          # Get the ID and security principal of the current user account
          $myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
          $myWindowsPrincipal = new-object System.Security.Principal.WindowsPrincipal($myWindowsID)

          # Get the security principal for the Administrator role
          $adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator

          # Check to see if we are currently running "as Administrator"
          if ($myWindowsPrincipal.IsInRole($adminRole))
          {
               # We are running "as Administrator" - so change the title and background color to indicate this
               $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
               #$Host.UI.RawUI.BackgroundColor = "DarkBlue"
               clear-host
          }
          else
          {
               # We are not running "as Administrator" - so relaunch as administrator

               # Create a new process object that starts PowerShell
               $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";

               # Specify the current script path and name as a parameter
               $newProcess.Arguments = $myInvocation.MyCommand.Definition;

               # Indicate that the process should be elevated
               $newProcess.Verb = "runas";

               # Start the new process
               [System.Diagnostics.Process]::Start($newProcess);

               # Exit from the current, unelevated, process
               exit
          }

          # Run your code that needs to be elevated here
          Microsoft.PowerShell.Utility\Write-Host -NoNewLine "Press any key to continue..."
          $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
     }
}

function Update-AllModules
{
     Import-Module -Name PowerShellGet -Force -ErrorAction Stop

     Microsoft.PowerShell.Utility\Write-Host ('Retrieving a list of all modules install on the system...')
     $allModules = ( Get-InstalledModule )

     foreach ($mod in $allModules)
     {
          Microsoft.PowerShell.Utility\Write-Host ('Checking for updates to ') -NoNewline
          Microsoft.PowerShell.Utility\Write-Host ($mod.Name) -ForegroundColor Green

          $modFound = (Find-Module -Name $mod.Name -ErrorAction SilentlyContinue)

          if ($modFound)
          {
               Microsoft.PowerShell.Utility\Write-Host ('Found {0} in available galleries' -f $mod.Name)

               if ($mod.Version -eq $modFound.Version)
               {
                    Microsoft.PowerShell.Utility\Write-Host ('No update required') -ForegroundColor Gray
               }
               elseif ($mod.Version -lt $modFound.Version)
               {
                    Microsoft.PowerShell.Utility\Write-Host ('Update found for {0}. Updating...' -f $mod.Name)
                    Update-Module -Name $mod.Name
                    Microsoft.PowerShell.Utility\Write-Host ('Update completed')
               }
          }
          else
          {
               Microsoft.PowerShell.Utility\Write-Host ('Unable to find {0} in currently available Repositories (or Repositories are currently unavailable)' -f $mod.Name)
          }
     }
}

function Get-TimeSinceStartDate
{
     [CmdletBinding()]
     param
     (
          [Parameter()]
          [Switch]
          $AsTimeSpan
     )

     process
     {
          $startDate = (Get-Date -Date "06/06/2017 10:00 AM")
          $contractLength = 12
          $elapsedTime = ((Get-Date).Subtract($StartDate))
          $timeLeft = ($StartDate.AddMonths($contractLength)).Subtract((Get-Date))

          if ($AsTimeSpan.IsPresent)
          {
               Write-Output ($ElapsedTime)
          }
          else
          {
               Write-Output ('{0:000} days, {1:00} hours, {2:00} minutes, {3:00} seconds, {4:0000} milliseconds elapsed' -f $ElapsedTime.Days,$ElapsedTime.Hours,$ElapsedTime.Minutes,$ElapsedTime.Seconds,$ElapsedTime.Milliseconds)
               Write-Output ('{0:000} days, {1:00} hours, {2:00} minutes, {3:00} seconds, {4:0000} milliseconds remaining' -f $timeLeft.Days,$timeLeft.Hours,$timeLeft.Minutes,$timeLeft.Seconds,$timeLeft.Milliseconds)
          }
     }
}

function Register-NugetPackageSource
{
     [CmdletBinding()]
     [OutputType()]

     param ()

     process
     {
          Register-PackageSource -Name Nuget.org -ProviderName NuGet -Location https://api.nuget.org/v3/index.json
     }
}
#endregion Misc-Commands

#region Network-Commands
function Get-ArpTable
{
     [CmdletBinding()]
     [OutputType()]

     param ()

     process
     {
$source = @"
namespace Netzwerker.Network.Diagnostics
{
     using System;
     using System.Collections.Generic;
     using System.ComponentModel;
     using System.Management.Automation;
     using System.Net;
     using System.Net.NetworkInformation;
     using System.Runtime.InteropServices;

     [Serializable]
     public class ArpEntry
     {
          public IPAddress Address;
          public PhysicalAddress MAC;
          public ArpEntryType Type;
          public int IndexAdapter;
          public int PhysAddrLength;

          internal ArpHost.MIB_IPNETROW GetRawStruct()
          {
               // Create object to be returned
               ArpHost.MIB_IPNETROW temp = new ArpHost.MIB_IPNETROW();

               // Copy index
               temp.dwIndex = IndexAdapter;

               // Copy IP
               #pragma warning disable 618
               temp.dwAddr = (int)Address.Address;
               #pragma warning restore 618

               // Copy MAC
               byte[] mac = MAC.GetBytes();
               temp.mac0 = mac[0];
               temp.mac1 = mac[1];
               temp.mac2 = mac[2];
               temp.mac3 = mac[3];
               temp.mac4 = mac[4];
               temp.mac5 = mac[5];
               temp.dwPhysAddrLen = 6;

               // Get Type
               temp.dwType = Type.GetHashCode();

               // Return object
               return temp;
          }

          public void Delete()
          {
               ArpHost.DeleteIpNetEntry(GetRawStruct());
          }
     }

     public enum ArpEntryType
     {
          Other = 1,
          Invalid = 2,
          Dynamic = 3,
          Static = 4,
     }

     public static class ArpHost
     {
          #region PInvoke Stuff

          // The max number of physical addresses.
          const int MAXLEN_PHYSADDR = 8;

          // The insufficient buffer error.
          const int ERROR_INSUFFICIENT_BUFFER = 122;

          // Define the MIB_IPNETROW structure.
          [StructLayout(LayoutKind.Sequential)]
          internal struct MIB_IPNETROW
          {
               [MarshalAs(UnmanagedType.U4)]
               public int dwIndex;
               [MarshalAs(UnmanagedType.U4)]
               public int dwPhysAddrLen;
               [MarshalAs(UnmanagedType.U1)]
               public byte mac0;
               [MarshalAs(UnmanagedType.U1)]
               public byte mac1;
               [MarshalAs(UnmanagedType.U1)]
               public byte mac2;
               [MarshalAs(UnmanagedType.U1)]
               public byte mac3;
               [MarshalAs(UnmanagedType.U1)]
               public byte mac4;
               [MarshalAs(UnmanagedType.U1)]
               public byte mac5;
               [MarshalAs(UnmanagedType.U1)]
               public byte mac6;
               [MarshalAs(UnmanagedType.U1)]
               public byte mac7;
               [MarshalAs(UnmanagedType.U4)]
               public int dwAddr;
               [MarshalAs(UnmanagedType.U4)]
               public int dwType;
          }

          // Declare the GetIpNetTable function.
          [DllImport("IpHlpApi.dll")]
          [return: MarshalAs(UnmanagedType.U4)]
          internal static extern int GetIpNetTable(IntPtr pIpNetTable, [MarshalAs(UnmanagedType.U4)]ref int pdwSize, bool bOrder);

          // Method that releases reserved memory
          [DllImport("IpHlpApi.dll", SetLastError = true, CharSet = CharSet.Auto)]
          internal static extern int FreeMibTable(IntPtr plpNetTable);

          // Flushes the arp table
          [DllImport("IpHlpApi.dll")]
          [return: MarshalAs(UnmanagedType.U4)]
          internal static extern int FlushIpNetTable(int dwIfIndex);

          // Creates a new arp entry
          [DllImport("IpHlpApi.dll")]
          [return: MarshalAs(UnmanagedType.U4)]
          internal static extern int CreateIpNetEntry(MIB_IPNETROW pArpEntry);

          // Deletes a new arp entry
          [DllImport("IpHlpApi.dll")]
          [return: MarshalAs(UnmanagedType.U4)]
          internal static extern int DeleteIpNetEntry(MIB_IPNETROW pArpEntry);

          #endregion PInvoke Stuff

          #region Main output methods

          public static void Clear(int AdapterIndex)
          {
               int temp = FlushIpNetTable(AdapterIndex);
               if (temp != 0) { throw new RuntimeException("An error occured while trying to flush the Arp table"); }
          }

          public static IList<ArpEntry> Get()
          {
               // The number of bytes needed.
               int bytesNeeded = 0;

               // The result from the API call.
               int result = GetIpNetTable(IntPtr.Zero, ref bytesNeeded, false);

               // Call the function, expecting an insufficient buffer.
               if (result != ERROR_INSUFFICIENT_BUFFER)
               {
                    // Throw an exception.
                    throw new Win32Exception(result);
               }

               // Allocate the memory, do it in a try/finally block, to ensure that it is released.
               IntPtr buffer = IntPtr.Zero;

               // Try/finally.
               try
               {
                    // Allocate the memory.
                    buffer = Marshal.AllocCoTaskMem(bytesNeeded);

                    // Make the call again. If it did not succeed, then raise an error.
                    result = GetIpNetTable(buffer, ref bytesNeeded, false);

                    // If the result is not 0 (no error), then throw an exception.
                    if (result != 0)
                    {
                    // Throw an exception.
                    throw new Win32Exception(result);
                    }

                    // Now we have the buffer, we have to marshal it. We can read the first 4 bytes to get the length of the buffer.
                    int entries = Marshal.ReadInt32(buffer);

                    // Increment the memory pointer by the size of the int.
                    IntPtr currentBuffer = new IntPtr(buffer.ToInt64() + Marshal.SizeOf(typeof(int)));

                    // Allocate an array of entries.
                    MIB_IPNETROW[] table = new MIB_IPNETROW[entries];

                    // Cycle through the entries.
                    for (int index = 0; index < entries; index++)
                    {
                    // Call PtrToStructure, getting the structure information.
                    table[index] = (MIB_IPNETROW)Marshal.PtrToStructure(new IntPtr(currentBuffer.ToInt64() + (index * Marshal.SizeOf(typeof(MIB_IPNETROW)))), typeof(MIB_IPNETROW));
                    }

                    // Collect results in this variable
                    IList<ArpEntry> Reports = new List<ArpEntry>();

                    // Iterate over each result
                    for (int index = 0; index < entries; index++)
                    {
                    // Create new report object
                    ArpEntry temp = new ArpEntry();

                    // Get IP Address
                    MIB_IPNETROW row = table[index];
                    temp.Address = new IPAddress(BitConverter.GetBytes(row.dwAddr));

                    // Get MAC Address
                    byte[] MacBytes = new byte[] { row.mac0, row.mac1, row.mac2, row.mac3, row.mac4, row.mac5 };
                    temp.MAC = new PhysicalAddress(MacBytes);

                    // Get Address Type
                    switch (row.dwType)
                    {
                         case 1:
                              temp.Type = ArpEntryType.Other;
                              break;
                         case 2:
                              temp.Type = ArpEntryType.Invalid;
                              break;
                         case 3:
                              temp.Type = ArpEntryType.Dynamic;
                              break;
                         case 4:
                              temp.Type = ArpEntryType.Static;
                              break;
                         default:
                              temp.Type = ArpEntryType.Invalid;
                              break;
                    }

                    // Get Index Adapter
                    temp.IndexAdapter = row.dwIndex;

                    // Get Physical Adapter Length
                    temp.PhysAddrLength = row.dwPhysAddrLen;

                    // Add Result to the results
                    Reports.Add(temp);
                    }

                    return Reports;
               }
               finally
               {
                    // Release the memory.
                    FreeMibTable(buffer);
               }
          }

          public static void New(IPAddress Address, PhysicalAddress MAC, int AdapterIndex)
          {
               // Create fictional ArpEntry
               ArpEntry temp = new ArpEntry();
               temp.Address = Address;
               temp.MAC = MAC;
               temp.IndexAdapter = AdapterIndex;
               temp.PhysAddrLength = 6;
               temp.Type = ArpEntryType.Static;

               // Create entry
               int res = CreateIpNetEntry(temp.GetRawStruct());

               // Report in case of error
               if (res != 0) { throw new InvalidOperationException("Unknown Error while writing entry"); }
          }

          #endregion Main output methods
     }

     /// <summary>
     /// A Physical Address (MAC) of a Network Adapter
     /// </summary>
     [Serializable]
     public class PhysicalAddress
     {
          /// <summary>
          /// The Byte Array that stores the physical address
          /// </summary>
          private byte[] _Bytes = new byte[6];

          public string Address
          {
               get
               {
                    return this.ToString();
               }
               set
               {
                    SetAddress(value);
               }
          }

          public PhysicalAddress()
          {

          }

          public PhysicalAddress(byte[] Bytes)
          {
               SetBytes(Bytes);
          }

          public PhysicalAddress(string Address)
          {
               try { SetAddress(Address); }
               catch (Exception e) { throw e; }
          }

          private void SetAddress(string Address)
          {
               // Split the address into hex bytes
               string[] temp = Address.Split('-');
               if (temp.Length != 6) { throw new ArgumentException("Invalid Address!"); }

               // Convert hex bytes into byte bytes
               byte[] bytes = new byte[6];

               try
               {
                    bytes[0] = Byte.Parse(temp[0], System.Globalization.NumberStyles.HexNumber);
                    bytes[1] = Byte.Parse(temp[1], System.Globalization.NumberStyles.HexNumber);
                    bytes[2] = Byte.Parse(temp[2], System.Globalization.NumberStyles.HexNumber);
                    bytes[3] = Byte.Parse(temp[3], System.Globalization.NumberStyles.HexNumber);
                    bytes[4] = Byte.Parse(temp[4], System.Globalization.NumberStyles.HexNumber);
                    bytes[5] = Byte.Parse(temp[5], System.Globalization.NumberStyles.HexNumber);

                    // Store the byte array
                    SetBytes(bytes);
               }
               catch { throw new ArgumentException("Invalid Address!"); }
          }

          public void SetBytes(byte[] Bytes)
          {
               if (Bytes.Length < 6) { throw new System.ArgumentException("Address too short to be a Physical Address"); }
               _Bytes[0] = Bytes[0];
               _Bytes[1] = Bytes[1];
               _Bytes[2] = Bytes[2];
               _Bytes[3] = Bytes[3];
               _Bytes[4] = Bytes[4];
               _Bytes[5] = Bytes[5];
          }

          public byte[] GetBytes()
          {
               byte[] temp = new byte[6];
               _Bytes.CopyTo(temp, 0);
               return temp;
          }

          public string GetManufacturerHex()
          {
               string temp = "";
               temp += _Bytes[0].ToString("X2");
               temp += _Bytes[1].ToString("X2");
               temp += _Bytes[2].ToString("X2");
               return temp;
          }

          public override string ToString()
          {
               try
               {
                    string temp = "";
                    temp += _Bytes[0].ToString("X2") + "-";
                    temp += _Bytes[1].ToString("X2") + "-";
                    temp += _Bytes[2].ToString("X2") + "-";
                    temp += _Bytes[3].ToString("X2") + "-";
                    temp += _Bytes[4].ToString("X2") + "-";
                    temp += _Bytes[5].ToString("X2");
                    return temp;
               }
               catch
               {
                    return "00-00-00-00-00-00";
               }
          }
     }
}
"@
          Add-Type $source
          c

          foreach ( $arpEntry in $ArpResults.GetEnumerator() )
          {
               $nicName = 'Virtual'
               $netAdpaterObj = ( Get-NetAdapter | Where-Object { $PSItem.InterfaceIndex -eq $arpEntry.IndexAdapter } )
               if ( $netAdpaterObj ) { $nicName = $netAdpaterObj.InterfaceDescription }

               $ifAddresses = ( Get-NetIPAddress -InterfaceIndex $arpEntry.IndexAdapter )
               Write-Output ([PSCustomObject] @{
                    IfIndex = $arpEntry.IndexAdapter
                    IfIpv4Addresses = ( ( $ifAddresses | Where-Object { $PSItem.AddressFamily -eq 'IPv4' } | ForEach-Object { $PSItem.IPAddress } ) -join ', ' )
                    PhysiclAddress = $arpEntry.MAC
                    InternetAddress = $arpEntry.Address
                    EntryType = $arpEntry.Type
                    IfAlias = ( ( $ifAddresses | ForEach-Object { $PSItem.InterfaceAlias } | Select-Object -Unique ) -join ', ' )
                    IfNicName = $nicName
                    PhysicalAddressLength = $arpEntry.PhysAddrLength
                    IfAddressOrigin = ( ( $ifAddresses | ForEach-Object { $PSitem.PrefixOrigin } ) -join ', ' )
                    IfAddressValidLifetime = ( ( $ifAddresses | ForEach-Object { $PSitem.ValidLifetime.ToString('c') } ) -join ', ' )
                    IfIpv6Addresses = ( ( $ifAddresses | Where-Object { $PSItem.AddressFamily -eq 'IPv6' } | ForEach-Object { $PSItem.IPAddress } ) -join ', ' )
               })
          }
     }
}
function Test-DnsNameResolutionByConnection
{
     [CmdletBinding()]
     [OutputType([PSCustomObject])]

     param
     (
          [Parameter(Mandatory = $true,
               ValueFromPipeline = $true,
               ValueFromPipelineByPropertyName = $true
          )]
          [ValidateNotNullOrEmpty()]
          # DNS name(s) to resolve
          [String[]]
          $DnsName
          ,
          [Parameter()]
          # Suppress Write-Host output
          [Switch]
          $Quiet
     )

     process
     {
          $ipPadding = (-18)
          $dnsNamePadding = ( -( $DnsName | Sort-Object -Property Length -Descending | Select-Object -First 1 | ForEach-Object { $PSItem.Length } ) + -4 )
          $separator = ('{0}-' -f ('-=' * 15))
          $ProgressPreference = 'SilentlyContinue'

          # Get all non-local interfaces with v4 IP addresses and IPAddress does not start with 169
          if ( -not $Quiet.IsPresent ) { Write-Host ('Gathering adapters with valid routable v4 IP addresses') -ForegroundColor Green }

          # Gather required interface information
          $iFaces = (Get-NetIPAddress -AddressFamily IPv4 | `
               Where-Object {
                    ($PSItem.InterfaceIndex -ge 10) -and `
                    (-not $PSItem.IPv4Address.StartsWith('16'))
               } | `
               ForEach-Object {
                    $ifIndex = $PSItem.InterfaceIndex
                    $naObj = Get-NetAdapter | Where-Object { $PSItem.InterfaceIndex -eq $ifIndex }

                    $ifDesc = [String]::Empty
                    if ($naObj)
                    { $ifDesc = $naObj.InterfaceDescription }
                    else
                    { $ifDesc = $PSItem.InterfaceAlias }

                    Write-Output ([PSCustomObject] @{
                         Index = $ifIndex
                         NIC = $ifDesc
                         Alias = $PSItem.InterfaceAlias
                         DnsServerIps = ( (Get-DnsClientServerAddress -InterfaceIndex $ifIndex).ServerAddresses | Where-Object { -not $PSItem.Contains(':') } | ForEach-Object { $PSItem.Trim() } )
                         LocalIpAddress = $PSItem.IPv4Address
                    })
               }
          )

          # Query DNS
          if ( -not $Quiet.IsPresent ) {
               Microsoft.PowerShell.Utility\Write-Host
               Write-Host ('{0} interfaces found matching criteria' -f $iFaces.Count) -ForegroundColor Green
               Microsoft.PowerShell.Utility\Write-Host
          }

          $iFaces | ForEach-Object {

               if ( -not $Quiet.IsPresent ) {
                    Write-Host ('NIC: {0} - {1}' -f $PSItem.NIC,$PSItem.LocalIpAddress) -ForegroundColor Blue -BackgroundColor White
                    Write-Host ($separator * 3) -ForegroundColor Blue -BackgroundColor White
                    Microsoft.PowerShell.Utility\Write-Host

                    Write-Host ("`tNIC IP {0}: Processing {1} DNS Server IPs" -f $PSItem.LocalIpAddress,$PSItem.DnsServerIps.Count)
                    Microsoft.PowerShell.Utility\Write-Host
               }

               foreach ($dnsIp in $PSItem.DnsServerIps)
               {
                    if ( -not $Quiet.IsPresent ) {
                         Write-Host ("`t`tDNS Server {0}: Processing {1} DNS Name(s)" -f $dnsIp,$DnsName.Count) -ForegroundColor DarkGreen -BackgroundColor White
                         Write-Host ("`t`t{0}" -f ($separator * 3)) -ForegroundColor DarkGreen -BackgroundColor White
                         Microsoft.PowerShell.Utility\Write-Host
                    }

                    $resultObj = [PSCustomObject] @{
                         Index = $PSItem.Index
                         NIC = $PSItem.NIC
                         Alias = $PSItem.Alias
                         IpAddress = $PSItem.LocalIpAddress
                         DnsServerIp = $dnsIp
                         NameResolutionResult = ([PSCustomObject[]] @())
                    }

                    foreach ($name in $DnsName)
                    {
                         Clear-DnsClientCache

                         $dnsQueryReturnObj = ([PSCustomObject] @{
                              DnsName = $name
                              CanResolveDns = $false
                              ResolvedIpAddresses = @{}
                              DnsErrorMessage = [String]::Empty
                         })

                         if ( -not $Quiet.IsPresent ) { Write-Host  ("`t`t`t`tName: {0,$dnsNamePadding}: DNS Server {1}" -f $name,$dnsIp) -ForegroundColor Green }
                         try
                         {
                              $dnsResult = ( Resolve-DnsName -Name $name -DnsOnly -NoHostsFile -Server $dnsIp -ErrorAction Stop )

                              Write-Debug ( 'DNS Query Result Information:' )
                              $recordCount = 1
                              $dnsResult | ForEach-Object { Write-Debug ('Record #{0:00}' -f $recordCount); Write-Debug ('Object Type: {0}' -f $PSItem.GetType().FullName); ( $PSItem | Format-List -Property * -Force | Out-String -Width 100 ).Trim() | Write-Debug; $recordCount++ }

                              $dnsQueryReturnObj.CanResolveDns = $true
                              $dnsQueryReturnObj.DnsErrorMessage = 'Success'
                              foreach ( $ipResult in $dnsResult )
                              {
                                   $recordValue = [String]::Empty
                                   $recordType = [String]::Empty
                                   if ( $ipResult -is [Microsoft.DnsClient.Commands.DnsRecord_PTR] )
                                   {
                                        $recordValue = $ipResult.Server
                                        $recordType = $ipResult.Type
                                        Write-Debug ('Record: PTR | Value: {0} | Type: {1}' -f $recordValue,$recordType)
                                        $dnsQueryReturnObj.ResolvedIpAddresses.Add( $recordValue,$recordType )
                                   }
                                   else
                                   {
                                        $recordValue = $ipResult.IPAddress
                                        $recordType = $ipResult.Type
                                        Write-Debug ('Record: PTR | Value: {0} | Type: {1}' -f $recordValue,$recordType)
                                        $dnsQueryReturnObj.ResolvedIpAddresses.Add( $recordValue,$recordType )
                                   }

                                   Write-Verbose ('Return Value:')
                                   ($dnsQueryReturnObj.ResolvedIpAddresses | Format-Table -AutoSize -Wrap | Out-String -Width 100).Trim() | Write-Verbose

                              }

                              if ( -not $Quiet.IsPresent ) {
                                   Write-Host ("`t`t`t`t{0,$dnsNamePadding}   : " -f 'Success - Resolved IP(s)   ') -ForegroundColor Green -NoNewline
                                   Microsoft.PowerShell.Utility\Write-Host ( "{0}" -f ( $dnsQueryReturnObj.ResolvedIpAddresses.Keys -join ', ') ) -ForegroundColor White
                              }
                         }
                         catch
                         {
                              $dnsQueryReturnObj.CanResolveDns = $false
                              $dnsQueryReturnObj.DnsErrorMessage = $PSItem.Exception.Message.Trim()

                              if ( -not $Quiet.IsPresent ) {
                                   Write-Host ("`t`t`t`t{0,$dnsNamePadding}      : " -f 'Error') -ForegroundColor Red -NoNewline
                                   Microsoft.PowerShell.Utility\Write-Host ("{0}" -f $PSItem.Exception.Message.Trim()) -ForegroundColor Red
                              }
                         }
                         finally
                         {
                              $resultObj.NameResolutionResult += $dnsQueryReturnObj
                         }

                         if ( -not $Quiet.IsPresent ) { Microsoft.PowerShell.Utility\Write-Host }
                    }
                    Write-Output ($resultObj) -NoEnumerate
               }
          }

          if ( -not $Quiet.IsPresent ) { Microsoft.PowerShell.Utility\Write-Host }
     }
}
#endregion Network-Commands

#region OS-And-Hardware
function Get-MemoryChipInformation
{
     [CmdletBinding()]
     [OutputType([PSCustomObject])]

     param ()

     begin
     {
          enum RamFormFactor
          {
               Unknown     = 0
               Other       = 1
               SIP         = 2
               DIP         = 3
               ZIP         = 4
               SOJ         = 5
               Proprietary = 6
               SIMM        = 7
               DIMM        = 8
               TSOP        = 9
               PGA         = 10
               RIMM        = 11
               SODIMM      = 12
               SRIMM       = 13
               SMD         = 14
               SSMP        = 15
               QFP         = 16
               TQFP        = 17
               SOIC        = 18
               LCC         = 19
               PLCC        = 20
               BGA         = 21
               FPBGA       = 22
               LGA         = 23
          }

          enum InterleavePosition
          {
               Noninterleaved = 0
               FirstPosition  = 1
               SecondPosition = 2
          }

          enum MemoryType
          {
               Unknown		  = 0
               Other		  = 1
               DRAM			  = 2
               Synchronous_DRAM = 3
               Cache_DRAM	  = 4
               EDO			  = 5
               EDRAM		  = 6
               VRAM			  = 7
               SRAM			  = 8
               RAM			  = 9
               ROM			  = 10
               Flash		  = 11
               EEPROM		  = 12
               FEPROM		  = 13
               EPROM		  = 14
               CDRAM		  = 15
               ThreeDRAM		  = 16
               SDRAM		  = 17
               SGRAM		  = 18
               RDRAM		  = 19
               DDR			  = 20
               DDR2			  = 21
               DDR2_FB_DIMM	  = 22
               DDR3			  = 24
               FBD2			  = 25
          }
     }

     process
     {
          $allMemSticks = ( Get-CimInstance -ClassName Win32_PhysicalMemory )

          foreach ( $stick in $allMemSticks )
          {
               Write-Output ( [PSCustomObject] @{
                    Name = ( $stick.Name )
                    CapacityGb = ( [Math]::Round( ($stick.Capacity / 1gb),2 ) )
                    Clock = ( '{0} [Max: {1}]' -f $stick.Speed,$stick.ConfiguredClockSpeed  )
                    BankLabel = ( $stick.BankLabel )
                    FormFactor = ( [RamFormFactor] ( $stick.FormFactor) )
                    MemoryType = ( [MemoryType] ( $stick.MemoryType ) )
                    CurrentClockSpeed = ( $stick.Speed )
                    SetClockSpeed = ( $stick.ConfiguredClockSpeed )
                    DeviceLocation = ( $stick.DeviceLocator )
                    CapacityBytes = ([Decimal] ( $stick.Capacity ) )
                    Bitness = ( $stick.DataWidth )
                    PartNumber = ( $stick.PartNumber )
                    Manufacturer = ( $stick.Manufacturer )
                    InterleaveDataDepth = ( $stick.InterleaveDataDepth  )
                    InterleavePosition = ( [InterleavePosition] ( $stick.InterleavePosition ) )
                    CimClassName = ( 'Win32_PhysicalMemory' )
               } )
          }
     }
}
#endregion OS-And-Hardware

#region PoSh-Development
function Format-PoshCodeFile
{
     [CmdletBinding()]
     [OutputType([String])]

     param
     (
          [Parameter(Mandatory = $true)]
          [ValidateNotNullOrEmpty()]
          # Path to file to be formatted
          [System.IO.FileInfo[]]
          $LiteralPath
          ,
          [Parameter()]
          # Output to console instead of clipboard
          [Switch]
          $OutputConsole
     )

     process
     {
          if ( -not ( Test-Path -LiteralPath $LiteralPath.FullName -PathType Leaf ) )
          {
               throw ( New-Object -TypeName System.IO.FileNotFoundException -ArgumentList ( 'Cannot access file "{0}"' -f $LiteralPath.FullName ) )
          }

          $fileStats = ( Get-Content .\CP-Utility.psm1 | Measure-Object -Character -Line -Word )
          $scriptContentsRaw = ( Get-Content -LiteralPath $LiteralPath.FullName -Raw )
          Write-Debug ( 'Retrieved contents of "{0}" containing {1} lines, {2} words, and {3} characters' -f $LiteralPath.FullName,$fileStats.Lines,$fileStats.Words,$fileStats.Characters )

          $formattedScriptContents = ( $scriptContentsRaw | `
               Format-ScriptFormatCodeIndentation |`
               Format-ScriptReduceLineLength |`
               Format-ScriptRemoveStatementSeparators |`
               Format-ScriptExpandFunctionBlocks |`
               Format-ScriptExpandNamedBlocks |`
               Format-ScriptExpandParameterBlocks |`
               Format-ScriptExpandStatementBlock |`
               Format-ScriptExpandTypeAccelerators |`
               Format-ScriptFormatCommandNames |`
               Format-ScriptFormatTypeNames |`
               Format-ScriptPadExpressions |`
               Format-ScriptPadOperators |`
               Format-ScriptRemoveSuperfluousSpaces |`
               Format-ScriptReplaceInvalidCharacters
          )

          if ( $OutputConsole.IsPresent )
          {
               $formattedScriptContents | Write-Host
          }
          else
          {
               $formattedScriptContents | Set-Clipboard
          }
     }
}
#endregion PoSh-Development

#region Profile-Commands
function Copy-VsLogs
{
     [CmdletBinding()]
     [OutputType()]

     param ()

     process
     {
          Write-Host

          $vsCodeProcesses = ( Get-Process -Name 'Code' -ErrorAction SilentlyContinue )
          if ( $vsCodeProcesses )
          {
               Write-Host ( 'Found {0} VS Code processes. Stopping' -f $vsCodeProcesses.Count ) -ForegroundColor Yellow
               $vsCodeProcesses | Stop-Process -Force
          }

          $sourceFolder = ( [System.IO.DirectoryInfo] ( '{0}\logs' -f ( Get-ChildItem -LiteralPath $HOME\.vscode\extensions -Filter *vscode.powershell* | Sort-Object -Property CreationTime -Descending | Select-Object -First 1 ).FulLName ) )
          $destFolder = ( [System.IO.DirectoryInfo] ( '\\scratch2\scratch\daviwil\ToddLogs' ) )

          Write-Host ( 'Source folder:        {0}' -f $sourceFolder.FullName )
          Write-Host ( 'Destination Folder:   {0}' -f $destFolder.FullName )

          $allFiles = Get-ChildItem -LiteralPath $sourceFolder.FullName -Recurse -File | Sort-Object -Property CreationTime -Descending

          $startTimeStamp = ( $allFiles[0].CreationTime.ToString('yyyyMMdd-HHmmss') )
          $endTimeStamp = ( $allFiles[-1].CreationTime.ToString('yyyyMMdd-HHmmss') )

          $zipFileArchivePath = ([System.IO.FileInfo] ('{0}\Desktop\{1}.vscodelogs.{2} to {3}.PoshArchive.zip' -f $HOME,$env:USERNAME,$startTimeStamp,$endTimeStamp) )

          $null = Compress-Archive -Destination $zipFileArchivePath.FullName -LiteralPath ([String[]] ( $allFiles | ForEach-Object { $PSItem.FUllName } ) ) -CompressionLevel Optimal -Update

          if ( Test-Path -LiteralPath $destFolder.FullName )
          {
               $null = Copy-Item -LiteralPath $zipFileArchivePath.FullName -Destination $destFolder.FullName -Force
               Write-Host ( "Archive {0} copied to:`r`n{1}" -f $zipFileArchivePath.Name,$destFolder.FulLName) -ForegroundColor Green
          }
          else
          {
               Write-Host ( "Unable to access {0}. Archive saved to:`r`n{1}" -f $destFolder.FullName,$zipFileArchivePath.Fullname ) -ForegroundColor Yellow
          }
          Write-Host
     }
}

function Export-VsCodeUserProfile
{
     [CmdletBinding()]
     [OutputType()]

     param
     (
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          # Username to back up
          [String]
          $Username = ($env:USERNAME)
          ,
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          # Destination to backup profile to
          [System.IO.DirectoryInfo]
          $Destination = ('{0}\Backups\VsCode' -f $env:OneDrive)
     )

     process
     {
          $Username = $Username.ToLower()
          $vsCodeProfPath = ([System.IO.DirectoryInfo] ('{0}\Users\{1}\AppData\Roaming\Code\User' -f $env:SystemDrive,$Username))
          $vsCodeProfPath.Refresh()

          if (-not $vsCodeProfPath.Exists)
          {
               throw (New-Object -TypeName System.IO.DirectoryNotFoundException -ArgumentList ('Cannot locate VS Code profile at "{0}"' -f $vsCodeProfPath.FullName))
          }

          ROBOCOPY $vsCodeProfPath.FullName $Destination.FullName *.* /MIR /R:10 /W:5 /ZB /V /NP /ETA
     }
}

function Import-CommandHistory
{
     [CmdletBinding()]
     param(
          [Parameter(ValueFromPipeline = $true)]
          [IO.FileInfo]
          $Path = (Join-Path -Path $Home -ChildPath .ps_history)
     )

     # Clear-History
     try
     {
          $xmlHist = Import-Clixml -Path $Path
          $count = 1
          foreach ($entry in $xmlHist)
          {
               $entry.Id = $count
               $count++
               Add-History -InputObject $entry
          }
     }
     catch [System.Xml.XmlException]
     {
          Write-Host ('Invalid XML detected. Clearing history file') -ForegroundColor DarkGray
          $null = Remove-Item -LiteralPath $Path.FullName -Force
     }
}

function Import-ProfileModules
{
     [CmdletBinding()]
     [OutputType()]

     param ()

     process
     {
          if ( -not ( Test-Path -LiteralPath $Script:PersonalModulesFolder.FullName -PathType Container ) )
          {
               throw ( New-Object -TypeName System.IO.DirectoryInfo -ArgumentList ( 'Cannot access personal modules folder at {0}' -f $Script:PersonalModulesFolder.FullName ) )
          }

          Import-Module -Name ( '{0}\Profile-Current.psm1' -f $Script:PersonalModulesFolder.FullName ) -Scope Global -Force

          if ($env:USERDOMAIN -ne $env:COMPUTERNAME)
          {
               Import-Module -Name ( '{0}\Profile-Work.psm1' -f $Script:PersonalModulesFolder.FullName ) -Scope Global -Force
          }
     }
}

function Open-VsCodeLogFolder
{
     [CmdletBinding()]
     [OutputType()]

     param ()

     process
     {
          start ('{0}\logs' -f ((Get-ChildItem -LiteralPath $HOME\.vscode\extensions -Filter *powershell* | Sort Name -Descending | Select -First 1).FullName))
     }
}

function Open-VsCodeUserFolder
{
     [CmdletBinding()]
     [OutputType()]

     param ()

     process
     {
          start ('{0}\Code\User' -f $env:APPDATA)
     }
}

function Prompt
{
     # Color for seperator ' -|- '
     $SeperatorColor = 'DarkGray'
     #	$SeperatorColor = Get-Random -Min 1 -Max 16

     # DateTime
     Microsoft.PowerShell.Utility\Write-Host "$([DateTime]::Now.ToString("MM/dd HH:mm:ss"))" -NoNewline -ForegroundColor Gray

     Microsoft.PowerShell.Utility\Write-Host (" -|- ") -NoNewline -ForegroundColor $SeperatorColor

     # IsAdmin
     $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
     $Principal = [Security.Principal.WindowsPrincipal] $identity

     if (Test-Path variable:/PSDebugContext)
     {
          Microsoft.PowerShell.Utility\Write-Host '[DBG]' -ForegroundColor Yellow -NoNewline
     }
     elseif ($principal.IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
     {
          Microsoft.PowerShell.Utility\Write-Host "[ADMIN]" -ForegroundColor Red -NoNewline
     }
     else
     {
          Microsoft.PowerShell.Utility\Write-Host "[NOADMIN]" -ForegroundColor Gray -NoNewline
     }

     Microsoft.PowerShell.Utility\Write-Host (" -|- ") -NoNewline -ForegroundColor $SeperatorColor

     $currentDirectory = Get-Location
     Microsoft.PowerShell.Utility\Write-Host ("History: {0:00}" -f ((Get-History).Count)) -ForegroundColor Gray #-NoNewline

     #	Microsoft.PowerShell.Utility\Write-Host (" -|- ") -NoNewline -ForegroundColor $SeperatorColor

     # Current folder
     Microsoft.PowerShell.Utility\Write-Host ("CWD: ") -ForegroundColor DarkGray -NoNewline
     Microsoft.PowerShell.Utility\Write-Host ("$($executionContext.SessionState.Path.CurrentLocation.ProviderPath.TrimEnd('\'))\") -ForegroundColor Green -NoNewline
     Microsoft.PowerShell.Utility\Write-Host ("$('>' * ($NestedPromptLevel + 1))")
}

function Show-CommandHistory
{
     [CmdletBinding()]
     [OutputType()]

     param ()

     process
     {
          ( Get-History | Format-Table -AutoSize -Wrap )
     }
}

function Start-QLApps
{
     $taskbarFldr = Join-Path -Path $env:APPDATA -ChildPath 'Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar' -Resolve

     $allLnks = Get-ChildItem -Path $taskbarFldr -Filter *.lnk -File

     foreach ($link in $allLnks)
     {
          Microsoft.PowerShell.Utility\Write-Host ('Starting {0}' -f $link.BaseName)
          Start-Process -FilePath $link.FullName
     }

     Start-Sleep -Seconds 10
     Exit 0
}
#endregion Profile-Commands

#region Shell-Commands
function ConvertTo-TitleCase
{
     [CmdletBinding()]
     param(
          [Parameter(Mandatory = $true,ValueFromPipeline = $true)]
          [ValidateNotNullOrEmpty()]
          [string]
          $InputObject,

          [Switch]
          $ToClipboard
     )

     $retVal = ((Get-Culture).TextInfo.ToTitleCase($InputObject.ToLower()))

     if ($ToClipboard.IsPresent)
     {
          Set-Clipboard -Value $retVal
          Write-Output $retVal
     }
     else
     {
          Write-Output $retVal
     }
}

function Copy-Hostname
{
     [CmdletBinding()]
     param (
          [switch]$Short = $true,
          [switch]$Domain = $false,
          [switch]$FQDN = $false
     )

     $ipProperties = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()
     if ( $FQDN )
     {
          Set-Clipboard ("{0}.{1}" -f $ipProperties.HostName.ToUpper(), $ipProperties.DomainName)
     }
     if ( $Domain )
     {
          Set-Clipboard ($ipProperties.DomainName.ToLower())
     }
     if ( $Short )
     {
          Set-Clipboard ($ipProperties.HostName.ToUpper())
     }
}

function Export-CommandHistory
{
     [CmdletBinding()]
     param(
          [Parameter(ValueFromPipeline = $true)]
          [IO.FileInfo]
          $Path = (Join-Path -Path $Home -ChildPath .ps_history)
     )

     $fullHistory = [Object[]] @()

     if (Test-Path -Path $Path)
     {
          $fullHistory += Import-Clixml -Path $Path
     }

     $fullHistory += Get-History

     $fullHistory | Sort-Object -Property StartExecutionTime | Select-Object -Unique| Export-Clixml -Path $Path -Force

}

function Get-Hostname
{
     # .SYNOPSIS
     #	Print the hostname of the system.
     # .DESCRIPTION
     #	This function prints the hostname of the system. You can additionally output the DNS
     #	domain or the FQDN by using the parameters as described below.
     # .PARAMETER Short
     #	(Default) Print only the computername, i.e. the same value as returned by $env:computername
     # .PARAMETER Domain
     #	If set, print only the DNS domain to which the system belongs. Overrides the Short parameter.
     # .PARAMETER FQDN
     #	If set, print the fully-qualified domain name (FQDN) of the system. Overrides the Domain parameter.

     param (
          [switch]$Short = $true,
          [switch]$Domain = $false,
          [switch]$FQDN = $false
     )

     $ipProperties = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()
     if ( $FQDN )
     {
          return "{0}.{1}" -f $ipProperties.HostName, $ipProperties.DomainName
     }
     if ( $Domain )
     {
          return $ipProperties.DomainName
     }
     if ( $Short )
     {
          return $ipProperties.HostName
     }
}

function Get-PerformanceHistory
{
     [CmdletBinding()]
     param(
          [ValidateNotNullOrEmpty()]
          [Int]
          $Count = 1,

          [ValidateNotNullOrEmpty()]
          [Int[]]
          $Id = @((Get-History -Count 1| Select Id).Id),

          [Switch]
          $PassThru
     )

     $Parser = [System.Management.Automation.PsParser]
     function FormatTimeSpan($ts)
     {
          if ($ts.Minutes)
          {
               if ($ts.Hours)
               {
                    if ($ts.Days)
                    {
                         return "{0:##}d {1:00}:{2:00}:{3:00}.{4:0000}" -f $ts.Days, $ts.Hours, $ts.Minutes, $ts.Seconds, $ts.Milliseconds
                    }

                    return "{0:##}:{1:00}:{2:00}.{3:0000}" -f $ts.Hours, $ts.Minutes, $ts.Seconds, $ts.Milliseconds
               }

               return "{0:##}:{1:00}.{2:0000}" -f $ts.Minutes, $ts.Seconds, $ts.Milliseconds
          }

          return "{0:#0}.{1:0000}" -f $ts.Seconds, $ts.Milliseconds
     }

     # if there's only one id, then the count counts, otherwise we just use the ids
     # ... basically:    { 1..$count | % { $id += $id[-1]-1 }  }
     if ($Id.Count -eq 1)
     {
          $Id = ($Id[0])..($Id[0] - ($Count - 1))
     }

     # so we can call it with just the IDs
     $cmdHistory = Get-History -Id $Id
     $measuredObjs = New-Object System.Collections.ArrayList
     foreach ($cmdId in $cmdHistory)
     {
          $msr = $null

          $tok = $Parser::Tokenize( $cmdId.CommandLine, [ref]$null )
          if ( ($tok[0].Type -eq "Number") -and
               ($tok[0].Content -le 1) -and
               ($tok[2].Type -eq "Number") -and
               ($tok[1].Content -eq "..") )
          {
               $Count = ([int]$tok[2].Content) - ([int]$tok[0].Content) + 1
          }

          $com = @( $tok | Where-Object {$PSItem.Type -eq "Command"} |
                    ForEach-Object { Get-Command $PSItem.Content -ErrorAction Ignore } |
                    Where-Object { $PSItem.CommandType -eq "ExternalScript" } |
                    ForEach-Object { $PSItem.Path } )

          # If we actually got a script, measure it out
          if ($com.Count -gt 0)
          {
               $msr = Get-Content -path $com | Measure-Object -Line -Word -Character
          }
          else
          {
               $msr = Measure-Object -in $cmdId.CommandLine -Line -Word -Character
          }

          $cmdType = $null

          if ($com.Count -gt 0)
          {
               $cmdType = "Script"
          }
          else
          {
               $cmdType = "Command"
          }

          [Void]$measuredObjs.Add( [PSCustomObject]@{
                    'Id'        = $cmdId.Id
                    'Duration'  = (FormatTimeSpan ($cmdId.EndExecutionTime - $cmdId.StartExecutionTime))
                    'Average'   = (FormatTimeSpan ([TimeSpan]::FromTicks( (($cmdId.EndExecutionTime - $cmdId.StartExecutionTime).Ticks / $Count) )))
                    'Lines'     = $msr.Lines
                    'Words'     = $msr.Words
                    'Chars'     = $msr.Characters
                    'Type'      = $cmdType
                    'Command'   = $cmdId.CommandLine
                    'StartTime' = $cmdId.StartExecutionTime
                    'EndTime'   = $cmdId.EndExecutionTime
               } )
     }

     # default formatting values
     $avgColSize = 0; $durColSize = 0; $typeColSize = 0

     # I have to figure out what the longest time string is to make it look its best
     foreach ($mObj in $measuredObjs)
     {
          if ($avgColSize -lt $mObj.Average.Length)
          {
               $avgColSize = $mObj.Average.Length
          }
          if ($durColSize -lt $mObj.Duration.Length)
          {
               $durColSize = $mObj.Duration.Length
          }
          if ($typeColSize -lt $mObj.Type.Length)
          {
               $typeColSize = $mObj.Type.Length
          }

     }

     if ($PassThru.IsPresent)
     {
          Write-Output $measuredObjs
     }
     else
     {
          $measuredObjs | `
               Sort-Object Id | `
               Format-Table Id,`
          @{l = ("{0,-$durColSize}" -f "Duration");e = {"{0:#.#,$durColSize}" -f $PSItem.Duration}},`
          @{l = ("{0,-$avgColSize}" -f "Average");e = {"{0:#.#,$avgColSize}" -f $PSItem.Average}},`
               Lines,`
               Words,`
               Chars,`
          @{l = ("{0,-$typeColSize}" -f "Type");e = {"{0:#.#,$typeColSize}" -f $PSItem.Type}},`
               Command `
               -AutoSize -Wrap
     }
}

function Lock-WorkStation
{
     $signature = @"
[DllImport("user32.dll", SetLastError = true)]
public static extern bool LockWorkStation();
"@

     $LockWorkStation = Add-Type -memberDefinition $signature -name "Win32LockWorkStation" -namespace Win32Functions -passthru
     $LockWorkStation::LockWorkStation() | Out-Null
}

function Set-PsReadLineConfiguration
{
     [CmdletBinding()]
     [OutputType()]

     param ()

     process
     {
          # CaptureScreen is good for blog posts or email showing a transaction
          # of what you did when asking for help or demonstrating a technique.
          Set-PSReadlineKeyHandler -Chord 'Ctrl+D,Ctrl+C' -Function CaptureScreen
     }
}

function Set-PSWindowTitle
{
     [CmdletBinding()]
     param
     (
          [ValidateNotNullOrEmpty()]
          [String]
          $Title
     )

     $Host.UI.RawUI.WindowTitle = $Title
}
#endregion Shell-Commands
#endregion Functions

#region Execution
# Path
Set-Location -LiteralPath $env:SystemDrive\

if (($Host.Name -eq 'ConsoleHost') -or ($Host.Name -eq 'Windows PowerShell ISE Host') -or ($Host.Name -eq 'Visual Studio Code Host'))
{

     # Window-Title
     Set-PSWindowTitle -Title ('Coding - {0}' -f (Get-Date -Format 'G'))

     # Modules
     Import-Module -Name PSReadline -Force -Global
     Set-PsReadLineConfiguration

     # Aliases
     New-Alias -Name ctc -Value ConvertTo-TitleCase -Force -Scope Global
     New-Alias -Name clip -Value Set-Clipboard -Force -Scope Global
     New-Alias -Name ch -Value Copy-Hostname -Force -Scope Global
     New-Alias -Name hostname -Value Get-Hostname -Force -Scope Global
     New-Alias -Name Set-Debug -Value Set-DebugPreference -Force -Scope Global
     New-Alias -Name Set-Verbose -Value Set-VerbosePreference -Force -Scope Global

     ### Persistent History ###
     $HistoryFilePath = Join-Path -Path ( [Environment]::GetFolderPath('UserProfile') ) -ChildPath '.ps_history'
     Register-EngineEvent PowerShell.Exiting -Action { Export-CommandHistory -Path $HistoryFilePath  } | Out-Null
     if (Test-path $HistoryFilePath)
     {
          Import-CommandHistory -Path $HistoryFilePath
     }

     #Set-DebugPreference -Preference Continue
     #Set-VerbosePreference -Preference Continue
     Set-InformationPreference -Preference Continue
}

Prompt
#endregion Execution