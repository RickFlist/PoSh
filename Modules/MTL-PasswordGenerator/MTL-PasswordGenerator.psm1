#Requires -Version 5.0
Set-StrictMode -Version Latest

#region Module-Configuration
#endregion Module-Configuration

#region Script-Variables
$Script:consoleSeperator = ('{0}-' -f ('-=' * 15))
$Script:ipStringPadding = (-18)
$ProgressPreference = 'SilentlyContinue'
$Script:PasswordWordList = ('{0}\lib\words.txt' -f $PSScriptRoot)
$Script:WordCache = ([String[]] @())
#endregion Script-Variables

#region Public-Functions
function New-WordBasedPassword
{
     [CmdletBinding()]
     [OutputType([String])]

     param
     (
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          # Number of words to include in password
          [Int]
          $WordCount = 4
          ,
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          # Absolute path to file containing word list. Words must be a plain text file with each word or phrase on a single line
          [System.IO.FileInfo]
          $WordListLiteralPath = ($Script:PasswordWordList)
          ,
          [Parameter()]
          # Forces reload of the world list if it is already cached
          [Switch]
          $ForceWordListReload
     )

     process
     {
          Write-Debug ('Word list expected location: {0}' -f $WordListLiteralPath.FullName)

          if (-not (Test-Path -LiteralPath $WordListLiteralPath.FullName -PathType Leaf))
          {
               throw (New-Object -TypeName System.OperationCanceledException -ArgumentList ('Cannot access word list at "{0}". That should be there. What have you done?!  If you need to get the word file again, it is words.txt at https://github.com/dwyl/english-words' -f $WordListLiteralPath.FullName))
          }
          else
          {
               Write-Verbose ('Word list exists at {0}' -f $WordListLiteralPath.FullName)
          }

          $allWords = ([String[]] @())
          if ( ( ($Script:WordCache.Count -ne 0) -and ($ForceWordListReload.IsPresent) ) -or ($Script:WordCache.Count -eq 0) )
          {
               Write-Verbose ('Loading word list ...')
               $wordListLoadStartTime = (Get-Date)
               $allWords = ([String[]] @( Get-Content -LiteralPath $WordListLiteralPath.FullName -ErrorAction Stop ))
               Write-Verbose ('World list loaded in {0} and contains {1} words' -f ((Get-Date).Subtract($wordListLoadStartTime)),$allWords.Count)
          }
          else
          {
               $allWords = $Script:WordCache
               Write-Verbose ('Cached word list found. Current word count: {0}' -f $allWords.Count)
          }

          Write-Verbose ('Generating password ...')

          $unformattedPasswords = @(Get-Random -InputObject $allWords -SetSeed (Get-Random) -Count 4)
          $sBuilder = New-Object -TypeName System.Text.StringBuilder
          for ( $i = 0; $i -lt $unformattedPasswords.Count; $i++ )
          {
               if ( ( ((Get-Random) % 2)  -eq 0  ) )
               {
                    $null = $sBuilder.Append( ('{0} ' -f $unformattedPasswords[$i].ToLower() ) )
               }
               else
               {
                    if ( ( ((Get-Random) % 2)  -eq 0  ) )
                    {
                         $null = $sBuilder.Append( ('{0} ' -f  $unformattedPasswords[$i].ToUpper() ) )
                    }
                    else
                    {
                         $null = $sBuilder.Append(  ('{0} ' -f ( (Get-Culture).TextInfo.ToTitleCase( $unformattedPasswords[$i].ToLower() ) ) ) )
                    }
               }
          }

          # Return password
          $sBuilder.ToString().Trim()

     }
}
#endregion Public-Functions

#region Private-Functions
#endregion Private-Functions

#region Execution
#endregion Execution