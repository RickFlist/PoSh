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
          ,
          [Parameter()]
          # Returns word list without spaces
          [Switch]
          $NoSpaces
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

          if ( $PSBoundParameters.ContainsKey('WordListLiteralPath') )
          {
               Write-Verbose ('Custom word list provided at path: {0}' -f $WordListLiteralPath.FullName)
               $Script:WordCache = ([String[]] @( Get-Content -LiteralPath $WordListLiteralPath.FullName -ErrorAction Stop ))
          }
          else
          {
               if ( ($Script:WordCache.Count -ne 0) -and ($ForceWordListReload.IsPresent) )
               {
                    Write-Verbose ('Cached word list found but a refresh of word cache is requested. Loading word list ...')
                    $wordListLoadStartTime = (Get-Date)
                    $Script:WordCache = ([String[]] @( Get-Content -LiteralPath $WordListLiteralPath.FullName -ErrorAction Stop ))
                    Write-Verbose ('Word list loaded in {0} and contains {1} words' -f ((Get-Date).Subtract($wordListLoadStartTime)),$Script:WordCache.Count)
               }
               elseif ($Script:WordCache.Count -gt 0)
               {
                    Write-Verbose ('Cached word list found. Current word count: {0}' -f $Script:WordCache.Count)
               }
               else
               {
                    Write-Verbose ('No cached word list found. Loading word list ...')
                    $wordListLoadStartTime = (Get-Date)
                    $Script:WordCache = ([String[]] @( Get-Content -LiteralPath $WordListLiteralPath.FullName -ErrorAction Stop ))
                    Write-Verbose ('Word list loaded in {0} and contains {1} words' -f ((Get-Date).Subtract($wordListLoadStartTime)),$Script:WordCache.Count)
               }
          }


          Write-Verbose ('Generating password ...')

          $unformattedPasswords = @(Get-Random -InputObject $Script:WordCache -SetSeed (Get-Random) -Count $WordCount)
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

          $returnString = [String]::Empty
          # Remove spaces from password if requested
          if ($NoSpaces.IsPresent)
          {
               Write-Debug ('-NoSpaces Parameter IS DETECTED. WILL remove spaces')
               $returnString = ( [String] ( $sBuilder.ToString().Replace(' ','').Trim() ) )
          }
          else
          {
               Write-Debug ('-NoSpaces parameter IS NOT DETECTED.WILL NOT remove spaces')
               $returnString = ( [String] ($sBuilder.ToString().Trim() ) )
          }

          # Return password
          Write-Host
          Write-Output ( $returnString )
          Write-Host
     }
}
#endregion Public-Functions

#region Private-Functions
#endregion Private-Functions

#region Execution
#endregion Execution