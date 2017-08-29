#region Script-Variables
$Script:EncryptedCredentialFile = ([System.IO.FileInfo] (Join-Path -Path $PSCommandPath -ChildPath 'EncryptedCredentials.txt'))
[System.Management.Automation.PSCredential]$Script:CachedCredential = [System.Management.Automation.PSCredential]::Empty

Write-Debug ('Default SQL Server: {0}' -f $Script:credStoreServer)
Write-Debug ('Default Credential Database: {0}' -f $Script:credDbName)
#endregion Script-Variables

#region Public-Functions
function Add-Account
{
     [CmdletBinding()]
     [OutputType([String])]

     param
     (
          [Parameter(Mandatory = $true)]
          [ValidateNotNullorEmpty()]
          [String]
          # Alias of account to add.
          $Username
          ,
          [Parameter(Mandatory = $true)]
          [ValidateNotNullorEmpty()]
          [String]
          # Password for account
          $Password
          ,
          [Parameter(Mandatory = $true)]
          [ValidateNotNullorEmpty()]
          [String]
          # Domain in which the account presides. Use "MACHINE" for local machine accounts
          $Domain
          ,
          [Parameter(Mandatory = $true)]
          [ValidateSet('S','L','C','D')]
          [String]
          # Type of account signified by a single letter (L = Local, D = Domain, C = Cloud, S = SQL)
          $Type
          ,
          [Parameter(Mandatory = $true)]
          [ValidateNotNullorEmpty()]
          [String]
          # Environment(s) account is used in, seperated by semi-colon ";"
          $Environment
          ,
          [Parameter(Mandatory = $true)]
          [ValidateNotNullorEmpty()]
          [String]
          # Short description of what account is used for
          $Description
          ,
          [Parameter()]
          [ValidateSet('Y','N')]
          [String]
          # For a temporary environment
          $Temporary = 'N'
          ,
          [Parameter()]
          [ValidateNotNullorEmpty()]
          [String]
          # Password expiration date
          $ExpirationDate = ((Get-Date).AddYears(1).ToUniversalTime())
          ,
          [Parameter()]
          [ValidateNotNullorEmpty()]
          [String]
          # Alias of person modifying accounty information
          $ModifiedBy = ($env:USERNAME.ToLower())
          ,
          [Parameter()]
          [ValidateSet('Y','N')]
          [String]
          # Indicates whether account is in use
          $Active = 'Y'
          ,
          [Parameter()]
          [ValidateNotNullorEmpty()]
          [String]
          # SQL server housing credential database
          $SqlServer = $Script:credStoreServer
          ,
          [Parameter()]
          [ValidateNotNullorEmpty()]
          [String]
          # Database name housing credentials
          $Database = $Script:credDbName
          ,
          [Parameter()]
          [Switch]
          # Return the result code of SQL stored procedure
          $PassThru
     )

     process
     {
          try
          {
               # Connection string
               #$dbConnString = [String] ("Data Source=$SqlServer; Authentication=Active Directory Integrated; Initial Catalog=$Database;")
               $dbConnString = [String] ("Data Source=$SqlServer; Authentication=Active Directory Integrated; Initial Catalog=$Database;")
               $LastModified = ((Get-Date).ToUniversalTime())

               Write-Debug ('Connection String: {0}' -f $dbConnString)

               $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
               $SqlConnection.ConnectionString = $dbConnString
               $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
               $SqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure
               $SqlCmd.CommandText = "sp_AccountAdd"
               $SqlCmd.Connection = $SqlConnection

               # Set Sproc parameter values
               $accParam = $SqlCmd.Parameters.Add('@AccountName', [System.Data.SqlDbType]::NVarChar)
               $accParam.Value = $Username.ToLower()

               $accPassword = $SqlCmd.Parameters.Add('@Password',[System.Data.SqlDbType]::NVarChar)
               $accPassword.Value = $Password

               $accExpDate = $SqlCmd.Parameters.Add('@ExpirationDate',[System.Data.SqlDbType]::DateTime)
               $accExpDate.Value = $ExpirationDate

               $accModDate = $SqlCmd.Parameters.Add('@LastModified',[System.Data.SqlDbType]::DateTime)
               $accModDate.Value = $LastModified

               $accModBy = $SqlCmd.Parameters.Add('@ModifiedBy',[System.Data.SqlDbType]::NVarChar)
               $accModBy.Value = $ModifiedBy.ToLower()

               $accDomain = $SqlCmd.Parameters.Add('@Domain',[System.Data.SqlDbType]::NVarChar)
               $accDomain.Value = $Domain.ToUpper()

               $accType = $SqlCmd.Parameters.Add('@Type',[System.Data.SqlDbType]::NVarChar)
               $accType.Value = $Type.ToUpper()

               $tempAcct = $SqlCmd.Parameters.Add('@Temporary',[System.Data.SqlDbType]::NVarChar)
               $tempAcct.Value = $Temporary.ToUpper()

               $accEnvironment = $SqlCmd.Parameters.Add('@Environment',[System.Data.SqlDbType]::NVarChar)
               $accEnvironment.Value = $Environment.ToUpper()

               $accActive = $SqlCmd.Parameters.Add('@Active',[System.Data.SqlDbType]::NVarChar)
               $accActive.Value = $Active.ToUpper()

               $accDesc = $SqlCmd.Parameters.Add('@Description', [System.Data.SqlDbType]::NVarChar)
               $accDesc.Value = $Description

               # Execute query
               $SqlConnection.Open()
               $sqlResult = $SqlCmd.ExecuteNonQuery()

               if ($PassThru.IsPresent)
               {
                    Write-Output ($sqlResult)
               }
               else
               {
                    if ($sqlResult -eq -1)
                    {
                         Write-Verbose ('Account {0} added successfully' -f $Username)
                    }
                    else
                    {
                         Write-Warning ('SQL result code is {0}. There was a possible error adding {1} to the credential store')
                    }
               }
          }
          catch [System.Data.SqlClient.SqlException]
          {
               if ($PSItem.Exception.Message -match 'Violation of UNIQUE KEY constraint')
               {
                    Write-Verbose ('Account {0} in environment {1} already exists in the Credential store. Use another command to edit this account''s information' -f $Username,$Environment.ToUpper())
               }
               else
               {
                    throw $PSItem.Exception
               }
          }
          catch [Exception]
          {
               throw $PSItem.Exception
          }
     }
}

function Get-CachedCredential
{
     PROCESS
     {
          Write-Output ($Script:CachedCredential)
     }
}

function Get-Password
{
     [CmdletBinding()]
     [OutputType([String])]

     param
     (
          [Parameter(Mandatory = $true)]
          [ValidateNotNullorEmpty()]
          [String]
          # Alias of account to retrieve. Exact match only
          $Username
          ,
          [Parameter(Mandatory = $true)]
          [ValidateNotNullorEmpty()]
          [String]
          # Environment that the account is used in
          $Environment
          ,
          [Parameter()]
          [ValidateNotNullorEmpty()]
          [String]
          # SQL server housing credential database
          $SqlServer = $Script:credStoreServer
          ,
          [Parameter()]
          [ValidateNotNullorEmpty()]
          [String]
          # Database name housing credentials
          $Database = $Script:credDbName
     )

     process
     {
          try
          {
               # $dbConnString = [String] ("Data Source=$SqlServer; Authentication=Active Directory Integrated; Initial Catalog=$Database;")
               $dbConnString = [String] ("Data Source=$SqlServer; Authentication=Active Directory Integrated; Initial Catalog=$Database;")
               Write-Debug ('Connection String: {0}' -f $dbConnString)

               $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
               $SqlConnection.ConnectionString = $dbConnString
               $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
               $SqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure
               $SqlCmd.CommandText = "sp_PasswordGet"
               $SqlCmd.Connection = $SqlConnection

               $usrParam = $SqlCmd.Parameters.Add('@AccountName', [System.Data.SqlDbType]::NVarChar)
               $usrParam.Value = $Username

               $envParam = $SqlCmd.Parameters.Add('@Environment', [System.Data.SqlDbType]::NVarChar)
               $envParam.Value = $Environment

               $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
               $SqlAdapter.SelectCommand = $SqlCmd
               $DataSet = New-Object System.Data.DataSet
               $SqlAdapter.Fill($DataSet) | Out-Null
               $SqlConnection.Close()

               Write-Output ($DataSet.Tables[0].Rows[0].Password)
          }
          catch [Exception]
          {
               throw $PSItem.Exception
          }
     }
}

function Install-EncryptionCertificate
{
     [CmdletBinding()]
     [OutputType()]

     param
     (
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          [String]
          # Password for PFX file
          $CertificatePassword = '#Ny@e85PaLV5umb'
     )

     process
     {
          Write-Host ('{0} {1} - Start {0}' -f $Script:HeaderCharacters, $MyInvocation.MyCommand) -ForegroundColor Green
          Write-Host

          Write-Host ('Downloading and installing MDP-Streams Encryption Certificate')

          if (-not (Test-Path $env:TEMP))
          {
               New-Item -Path $env:TEMP -ItemType Directory -Force | Out-Null
          }

          $destFolder = Get-Item -LiteralPath $env:TEMP
          $pfxFileName = 'MdpEncryptionCertificate.pfx'
          $pfxUri = [Uri] ('https://mdpgeneral.blob.core.windows.net/runascert/{0}' -f $pfxFileName)
          $destFile = [System.IO.FileInfo] (Join-Path -Path $destFolder.FullName -ChildPath $pfxFileName)

          $wc = New-Object System.Net.WebClient
          Write-Host ('Downloading MDP-Streams Encryption Certificate from ''{0}'' to ''{1}''' -f $pfxUri.ToString(), $destFile.FullName)
          $wc.DownloadFile($pfxUri, $destFile.FullName)
          Write-Host ('Certificate downloaded')

          Write-Host ('Installing Certificate')
          $secCertPass = ConvertTo-SecureString -String $CertificatePassword -AsPlainText -Force

          Write-Host
          Write-Host ('Installing MDP-Streams Encryption Certificate to Cert:\CurrentUser\My')
          Import-PfxCertificate -FilePath $destFile.FullName -CertStoreLocation Cert:\CurrentUser\My -Password $secCertPass -Exportable | Out-Host

          Write-Host
          Write-Host ('Installing MDP-Streams Encryption Certificate to Cert:\LocalMachine\My')
          Import-PfxCertificate -FilePath $destFile.FullName -CertStoreLocation Cert:\LocalMachine\My -Password $secCertPass -Exportable | Out-Host
          Write-Host

          Write-Host ('MDP-Streams Encryption Certficate Installed')
          Write-Host ('Deleting pfx file')
          $destFile.Refresh()
          if ($destFile.Exists)
          {
               $destFile.Delete()
          }

          Write-Host
          Write-Host ('{0} {1} - End {0}' -f $Script:HeaderCharacters, $MyInvocation.MyCommand) -ForegroundColor Green
     }
}

function Install-RunAsCertificate
{
     [CmdletBinding()]
     [OutputType()]

     param
     (
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          [String]
          # Password for PFX file
          $CertificatePassword = '#Ny@e85PaLV5umb'
     )

     process
     {
          Write-Host ('{0} {1} - Start {0}' -f $Script:HeaderCharacters, $MyInvocation.MyCommand) -ForegroundColor Green
          Write-Host

          Write-Host ('Downloading and installing AzureRM RunAs Certificate')

          if (-not (Test-Path $env:TEMP))
          {
               New-Item -Path $env:TEMP -ItemType Directory -Force | Out-Null
          }

          $destFolder = Get-Item -LiteralPath $env:TEMP
          $pfxFileName = 'AzureRunAsCertificate.pfx'
          $pfxUri = [Uri] ('https://mdpgeneral.blob.core.windows.net/runascert/{0}' -f $pfxFileName)
          $destFile = [System.IO.FileInfo] (Join-Path -Path $destFolder.FullName -ChildPath $pfxFileName)

          $wc = New-Object System.Net.WebClient
          Write-Host ('Downloading RunAs Certificate from ''{0}'' to ''{1}''' -f $pfxUri.ToString(), $destFile.FullName)
          $wc.DownloadFile($pfxUri, $destFile.FullName)
          Write-Host ('Certificate downloaded')

          Write-Host ('Installing Certificate')
          $secCertPass = ConvertTo-SecureString -String $CertificatePassword -AsPlainText -Force

          Write-Host
          Write-Host ('Installing RunAs Certificate to Cert:\CurrentUser\My')
          Import-PfxCertificate -FilePath $destFile.FullName -CertStoreLocation Cert:\CurrentUser\My -Password $secCertPass -Exportable | Write-Host

          Write-Host
          Write-Host ('Installing RunAs Certificate to Cert:\LocalMachine\My')
          Import-PfxCertificate -FilePath $destFile.FullName -CertStoreLocation Cert:\LocalMachine\My -Password $secCertPass -Exportable | Write-Host
          Write-Host

          Write-Host ('RunAs Certficate Installed')
          Write-Host ('Deleting pfx file')
          $destFile.Refresh()
          if ($destFile.Exists)
          {
               $destFile.Delete()
          }

          Write-Host
          Write-Host ('{0} {1} - End {0}' -f $Script:HeaderCharacters, $MyInvocation.MyCommand) -ForegroundColor Green
     }
}

function New-Credential
{
     [CmdletBinding()]
     [OutputType([PSCredential])]

     param
     (
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          [String]
          # Username
          $Username
          ,
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          [String]
          # Password
          $Password
     )

     process
     {
          $secPass = ConvertTo-SecureString -String $Password -AsPlainText -Force
          Write-Output (New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username,$secPass)
     }
}

function New-EncryptionCertificate
{
     [CmdletBinding()]
     [OutputType()]

     param
     (
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          [String]
          # Password for PFX file
          $CertificatePassword = '#Ny@e85PaLV5umb'
     )

     process
     {
          # note: These steps need to be performed in an Administrator PowerShell session
          #$cert = New-SelfSignedCertificate -Type DocumentEncryptionCertLegacyCsp -DnsName 'MdpEncryptionCetificate' -HashAlgorithm SHA256
          $cert = New-SelfSignedCertificate -Type DocumentEncryptionCert -DnsName 'MdpEncryptionCertificate' -HashAlgorithm SHA256 -KeyUsage 'KeyEncipherment','DataEncipherment' -KeyUsageProperty All
          # export the public key certificate
          $exportSecPwd = ConvertTo-SecureString -String $CertificatePassword -AsPlainText -Force
          $cert | Export-PfxCertificate -FilePath "MdpEncryptionCertificate.pfx" -Password $exportSecPwd -Force
     }
}

function New-RandomNumber
{
     [CmdletBinding()]
     [OutputType()]

     param
     (
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          # Minimum random number value
          [Int]
          $MinimumNumber = 1
          ,
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          # Maximum random number value
          [Int]
          $MaximumNumber = 100
     )

     process
     {
          # From https://stackoverflow.com/questions/6299197/rngcryptoserviceprovider-generate-number-in-a-range-faster-and-retain-distribu which references an MSDN magazine article I could not find

          $rngProvider = (New-Object -TypeName System.Security.Cryptography.RNGCryptoServiceProvider)
          while ($true)
          {
               if ( $MinimumNumber -eq $MaximumNumber ) { return $MaximumNumber }

               $ranNumByteArr = New-Object -TypeName byte[] -ArgumentList 4
               $rngProvider.GetBytes( $ranNumByteArr )
               $randomNumber = [BitConverter]::ToInt32( $ranNumByteArr,0 )

               $intMaxValue = (1 + [Int]::MaxValue)
               $numRange = ( $MaximumNumber - $MinimumNumber )
               $remainder = ( $intMaxValue - $numRange )

               if ( $randomNumber -lt ( $intMaxValue - $numRange ) )
               {
                    $retValue = ( [Int] ( $MinimumNumber + ( $randomNumber % $numRange ) ) )

                    if ($retValue -lt 0) { return ( $retValue * -1 ) } else { return $retValue }
               }
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

          $selectedWordList = New-Object -TypeName System.Collections.ArrayList
          for ( $i = 0; $i -lt $WordCount; $i++ )
          {
               Write-Debug ('Password Generation Iteration {0:00}' -f $i)

               $wordIndex = New-RandomNumber -MinimumNumber 0 -MaximumNumber $Script:WordCache.Count
               Write-Debug ('Total Word Count: {0}, Word Index: {1}' -f $Script:WordCache.Count,$wordIndex)

               $chosenWord = $Script:WordCache[$wordIndex]
               $null = $selectedWordList.Add( $chosenWord )
               Write-Debug ('Selected Word: {0}' -f $chosenWord)
          }

          $sBuilder = New-Object -TypeName System.Text.StringBuilder
          for ( $i = 0; $i -lt $selectedWordList.Count; $i++ )
          {
               if ( ( ((New-RandomNumber) % 2)  -eq 0  ) )
               {
                    $null = $sBuilder.Append( ('{0} ' -f $selectedWordList[$i].ToLower() ) )
               }
               else
               {
                    if ( ( ((New-RandomNumber) % 2)  -eq 0  ) )
                    {
                         $null = $sBuilder.Append( ('{0} ' -f  $selectedWordList[$i].ToUpper() ) )
                    }
                    else
                    {
                         $null = $sBuilder.Append(  ('{0} ' -f ( (Get-Culture).TextInfo.ToTitleCase( $selectedWordList[$i].ToLower() ) ) ) )
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

function Protect-Credential
{
     [CmdletBinding()]
     [OutputType([String])]

     param
     (
          [Parameter(Mandatory = $true)]
          [ValidateNotNullOrEmpty()]
          [String]
          # Username
          $Username
          ,
          [Parameter(Mandatory = $true)]
          [ValidateNotNullOrEmpty()]
          [String]
          # Password
          $Password
     )

     process
     {
          <#
        This cmdlet encrypts credential objects using the certificate for the RunAs account GeneralAutomation that is installed when a VM is provisioned.
        You must have the GA certificate installed in order to encrypt/decrypt credentials.
        Use Install-MdpRunAsCertificate to install the certificate in your certificate store.

        I create a PSCustomObject with the values for username and password, then I convert that to a JSON object, and then I encrypt the JSON object and then encode it as a Base64 string

        Inspired by: https://www.cgoosen.com/2016/05/using-a-certificate-to-encrypt-credentials-in-automated-powershell-scripts-an-update/
        #>

          $psObj = [PSCustomObject] @{
               Username = $Username.ToLower()
               Password = $Password
          }

          $jsonObj = $psObj | ConvertTo-Json

          $certSearchString = 'MdpEncryptionCertificate'
          $certPath = 'Cert:\LocalMachine\My'
          $Cert = Get-ChildItem -Path $certPath | Where-Object {$PSItem.Subject -match $certSearchString}

          if (-not $Cert)
          {
               throw (New-Object -TypeName System.InvalidOperationException -ArgumentList ('Cannot find a certificate in the local certificate store ''{0}'' that matches the name ''{1}''' -f $certPath,$certSearchString))
          }

          $cmsMessage = Protect-CmsMessage -To $Cert -Content $jsonObj
          $cmsByteArr = [System.Text.Encoding]::UTF8.GetBytes($cmsMessage)
          $cmsBase64String = [System.Convert]::ToBase64String($cmsByteArr)

          <#
        $EncodedPwd = [System.Text.Encoding]::UTF8.GetBytes($jsonObj)
        $EncryptedBytes = $Cert.PublicKey.Key.Encrypt($EncodedPwd, $true)
        $EncryptedPwd = [System.Convert]::ToBase64String($EncryptedBytes)
        #>

          return $cmsBase64String
     }
}

function Remove-Account
{
     [CmdletBinding()]
     [OutputType()]

     param
     (
          [Parameter(Mandatory = $true)]
          [ValidateNotNullorEmpty()]
          [String]
          # Alias of account to modify. Exact match only
          $Username
          ,
          [Parameter()]
          [ValidateNotNullorEmpty()]
          [String]
          # SQL server housing credential database
          $SqlServer = $Script:credStoreServer
          ,
          [Parameter()]
          [ValidateNotNullorEmpty()]
          [String]
          # Database name housing credentials
          $Database = $Script:credDbName
     )

     process
     {
          try
          {
               # Connection string
               $dbConnString = [String] ("Data Source=$SqlServer; Authentication=Active Directory Integrated; Initial Catalog=$Database;")

               Write-Debug ('Connection String: {0}' -f $dbConnString)

               $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
               $SqlConnection.ConnectionString = $dbConnString
               $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
               $SqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure
               $SqlCmd.CommandText = "sp_AccountSetInactive"
               $SqlCmd.Connection = $SqlConnection

               # Sproc parameters
               $usrParam = $SqlCmd.Parameters.Add('@AccountName', [System.Data.SqlDbType]::NVarChar)
               $usrParam.Value = $Username.ToLower()

               # Execute query
               $SqlConnection.Open()
               $sqlResult = $SqlCmd.ExecuteNonQuery()
          }
          catch
          {
               throw $PSItem.Exception
          }
     }
}

function Remove-CachedCredential
{
     PROCESS
     {
          $Script:CachedCredential = [System.Management.Automation.PSCredential]::Empty
     }
}

function Remove-AccountsByEnvironment
{
     [CmdletBinding()]
     [OutputType()]

     param
     (
          [Parameter(Mandatory = $true)]
          [ValidateNotNullOrEmpty()]
          [String]
          # Environment to remove accounts for
          $Environment
          ,
          [Parameter()]
          [ValidateNotNullorEmpty()]
          [String]
          # SQL server housing credential database
          $SqlServer = $Script:credStoreServer
          ,
          [Parameter()]
          [ValidateNotNullorEmpty()]
          [String]
          # Database name housing credentials
          $Database = $Script:credDbName
     )

     process
     {
          try
          {
               # Connection string
               $dbConnString = [String] ("Data Source=$SqlServer; Authentication=Active Directory Integrated; Initial Catalog=$Database;")

               Write-Debug ('Connection String: {0}' -f $dbConnString)

               $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
               $SqlConnection.ConnectionString = $dbConnString
               $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
               $SqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure
               $SqlCmd.CommandText = "sp_RemoveEnvironment"
               $SqlCmd.Connection = $SqlConnection

               # Sproc parameters
               $usrParam = $SqlCmd.Parameters.Add('@Environment', [System.Data.SqlDbType]::NVarChar)
               $usrParam.Value = $Environment

               # Execute query
               $SqlConnection.Open()
               $sqlResult = $SqlCmd.ExecuteNonQuery()
               Write-Host ('{0} accounts removed for environment ''{1}''' -f $sqlResult,$Environment)
          }
          catch
          {
               throw $PSItem.Exception
          }
     }
}

function Set-CachedCredential
{
     [CmdletBinding()]
     [OutputType()]

     param
     (
          [Parameter(Mandatory = $true)]
          [ValidateNotNullOrEmpty()]
          [System.Management.Automation.PSCredential]
          # Credential to place in cache
          $Credential
     )

     PROCESS
     {
          $Script:CachedCredential = $Credential
     }
}

function Set-Password
{
     [CmdletBinding()]
     [OutputType()]

     param
     (
          [Parameter(Mandatory = $true)]
          [ValidateNotNullorEmpty()]
          [String]
          # Alias of account to modify. Exact match only
          $Username
          ,
          [Parameter(Mandatory = $true)]
          [ValidateNotNullorEmpty()]
          [String]
          # New password for account
          $Password
          ,
          [Parameter(Mandatory = $true)]
          [ValidateNotNullorEmpty()]
          [String]
          # Environment in which the account is used
          $Environment
          ,
          [Parameter()]
          [ValidateNotNullorEmpty()]
          [String]
          # SQL server housing credential database
          $SqlServer = $Script:credStoreServer
          ,
          [Parameter()]
          [ValidateNotNullorEmpty()]
          [String]
          # Database name housing credentials
          $Database = $Script:credDbName
     )

     process
     {
          try
          {
               # Connection string
               $dbConnString = [String] ("Data Source=$SqlServer; Authentication=Active Directory Integrated; Initial Catalog=$Database;")

               Write-Debug ('Connection String: {0}' -f $dbConnString)

               $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
               $SqlConnection.ConnectionString = $dbConnString
               $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
               $SqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure
               $SqlCmd.CommandText = "sp_PasswordUpdate"
               $SqlCmd.Connection = $SqlConnection

               # Sproc parameters
               $usrParam = $SqlCmd.Parameters.Add('@AccountName', [System.Data.SqlDbType]::NVarChar)
               $usrParam.Value = $Username.ToLower()

               $passParam = $SqlCmd.Parameters.Add('@Password', [System.Data.SqlDbType]::NVarChar)
               $passParam.Value = $Password

               $envParam = $SqlCmd.Parameters.Add('@Environment',[System.Data.SqlDbType]::NVarChar)
               $envParam.Value = $Environment

               # Execute query
               $SqlConnection.Open()
               $sqlResult = $SqlCmd.ExecuteNonQuery()
          }
          catch
          {
               throw $PSItem.Exception
          }
     }
}

function Set-ServiceAccountAdPassword
{
     [CmdletBinding()]
     [OutputType()]

     param
     (
          [Parameter(Mandatory = $true)]
          [ValidateNotNullOrEmpty()]
          [String]
          # Username to reset password for
          $Username
          ,
          [Parameter(Mandatory = $true)]
          [ValidateNotNullOrEmpty()]
          [String]
          # Old password for account
          $CurrentPassword
          ,
          [Parameter(Mandatory = $true)]
          [ValidateNotNullOrEmpty()]
          [String]
          # Username to reset password for
          $NewPassword
          ,
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          [String]
          # Domain user account lives in. Will default to the domain of the current PowerShell session ($env:USERDOMAIN)
          $Domain = $env:USERDOMAIN
     )

     process
     {
          <#
        $passesAuth = Test-UserAuthentication -Username $Username -Password $CurrentPassword
        if (-not $passesAuth)
        {
            throw (New-Object -TypeName System.InvalidOperationException -ArgumentList ('Unable to authenticate ''{0}'' with current password. Please check your typing and try again' -f $Username))
        }
        #>

          $fullUserName = ('{0}\{1}' -f $Domain,$Username)
          $currentCreds = New-MdpCredential -Username $fullUserName -Password $CurrentPassword
          $secOldPassword = ConvertTo-SecureString -String $CurrentPassword -AsPlainText -Force
          $secNewPassword = ConvertTo-SecureString -String $NewPassword -AsPlainText -Force
          #Set-ADAccountPassword -Credential $currentCreds -Identity $Username -Server $Domain -NewPassword $secNewPassword -OldPassword $secOldPassword
          #Set-ADAccountPassword -Credential $currentCreds -Identity $Username -Server $Domain -OldPassword $secOldPassword -Reset
          Set-ADAccountPassword -Identity $Username -Server $Domain -NewPassword $secNewPassword -OldPassword $secOldPassword
     }
}

function Test-UserAuthentication
{
     [CmdletBinding()]
     [OutputType()]

     param
     (
          [Parameter(Mandatory = $true)]
          [ValidateNotNullOrEmpty()]
          [String]
          # Username to test
          $Username
          ,
          [Parameter(Mandatory = $true)]
          [ValidateNotNullOrEmpty()]
          [String]
          # Password for username
          $Password
     )

     process
     {
          # Return value
          $authPass = $false

          # Get current domain using logged-on user's credentials
          $CurrentDomain = "LDAP://" + ([ADSI]"").distinguishedName
          $domain = New-Object -TypeName System.DirectoryServices.DirectoryEntry -ArgumentList @($CurrentDomain,$Username,$Password)

          if ($domain.name -ne $null)
          {
               $authPass = $true
               Write-Verbose ('Authentication successful for user ''{0}'' against domain ''{1}''' -f $Username,$CurrentDomain)
          }
          else
          {
               Write-Verbose ('Authentication failed for user ''{0}'' against domain ''{1}''' -f $Username,$CurrentDomain)
          }

          return $authPass
     }
}

function Unprotect-Credential
{
     [CmdletBinding()]
     [OutputType([PSCustomObject])]

     param
     (
          [Parameter(Mandatory = $true)]
          [ValidateNotNullOrEmpty()]
          [String]
          # Username
          $EncryptedString
     )

     process
     {
          <#
        This cmdlet encrypts credential objects using the certificate for the RunAs account GeneralAutomation that is installed when a VM is provisioned.
        You must have the GA certificate installed in order to encrypt/decrypt credentials.
        Use Install-MdpRunAsCertificate to install the certificate in your certificate store.

        I create a PSCustomObject with the values for username and password, then I convert that to a JSON object, and then I encrypt the JSON object and then encode it as a Base64 string

        Inspired by: https://www.cgoosen.com/2016/05/using-a-certificate-to-encrypt-credentials-in-automated-powershell-scripts-an-update/
        #>

          $certSearchString = 'MdpEncryptionCertificate'
          $certPath = 'Cert:\LocalMachine\My'
          $Cert = Get-ChildItem -Path $certPath | Where-Object {$PSItem.Subject -match $certSearchString}

          if (-not $Cert)
          {
               throw (New-Object -TypeName System.InvalidOperationException -ArgumentList ('Cannot find a certificate in the local certificate store ''{0}'' that matches the name ''{1}''' -f $certPath,$certSearchString))
          }


          $encodedBytes = [System.Convert]::FromBase64String($EncryptedString)
          $decodedCred = [System.Text.Encoding]::UTF8.GetString($encodedBytes)

          $decryptedCred = Unprotect-CmsMessage -Content $decodedCred -To $Cert.Thumbprint -IncludeContext
          $decryptedObj = ($decryptedCred | ConvertFrom-Json)

          $psCredObj = New-Credential -Username $decryptedObj.Username -Password $decryptedObj.Password

          Write-Output $psCredObj -NoEnumerate
     }
}

function Unprotect-SecureString
{
     [CmdletBinding()]
     [OutputType([String])]

     param
     (
          [Parameter(Mandatory = $true)]
          [ValidateNotNullOrEmpty()]
          [SecureString]
          # SecureString to be decyrpted
          $SecureString
     )

     process
     {
          $decryptedSecret = [System.Runtime.InteropServices.marshal]::PtrToStringAuto([System.Runtime.InteropServices.marshal]::SecureStringToBSTR($SecureString))
          Write-Output ($decryptedSecret)
     }
}
#endregion Public-Functions

#region Private-Functions
#endregion Private-Functions