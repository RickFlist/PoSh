#region Script-Variables
# Encypted credential file
$Script:EncCredFileObj = [System.IO.FileInfo] (Join-Path -Path $PSCommandPath -ChildPath 'CredentialStorage.txt')
# Certificate DNS Name
$Script:CertDnsName = ('MtlCipherCertificate')
# Certificate PFX default passsword
$Script:CertPfxDefaultPassword = '#Ny@e85PaLV5umb' <# Yes, I am aware the gaping whole in security this is. This was originally designed to use an
                                                       AD authenticated SQL database to get this information. This module is for demonstration purposes
                                                       only. This is a problem that would need to be solved before using this code in a production
                                                       environment. I could perhaps have taken steps to at least secure this information in the demonstration
                                                       but I felt it would all be throwaway code as it is unlikely this information would be kept on the
                                                       destination machine in any way. #>

# DateStamp format
$Script:DateStampFormat = 'yyyyMMdd HH:mm:ss'

# for display purposes
$Script:HeaderCharacters = ('=' * 20)
#endregion Script-Variables

#region Public-Functions

#region Account-Management
function New-RandomPassword
{
     <#
    .Synopsis
       Generates one or more complex passwords
    .DESCRIPTION
       Generates one or more complex passwords of varying lengths and from customizable character sets
    .EXAMPLE
       New-RandomPassword
       C&3SX6Kn

       Will generate one password with a length between 8  and 12 chars.
    .EXAMPLE
       New-RandomPassword
       F9i#Q4mkV2t12%Z

       Generates a single password of the default length of 15 characters
    .EXAMPLE
       New-RandomPassword -InputStrings abc,ABC,123
       cabC2acAB22bb2b

       Generates a password with the default length of 15 using the specified character set
    .EXAMPLE
       New-RandomPassword -Count 10
       w#FTh4qEamWsRfk
       xGHx%8512usNre1
       f6r6EEH2ES6#b3s
       qdaZSd@#&@1Jz8M
       kZER9KZ9KVGe@y#
       r3wYHy3%#!4NS%j
       T6Cgixf1npbtq!G
       GFHTrcW%G%bq&2p
       @Y1RwV6x8Z@Cr7c
       %%iu6uzm2XE57ez

       Generates 10 passwords of default length of 15 characters

    .EXAMPLE
       New-RandomPassword -FirstChar O -Count 5
       O1bt!7e#R9G&&%A
       Of7KgEHfJ!eZaQ4
       OJ1#b8Q1RTcyu%8
       O9utnh&y2PUFYd8
       OZC45BUzgX3f2w@

       Generates 5 passwords of default character length 15 that begin with a specific character. Useful for systems that require the first character to be a letter, number, or non-alphanumeric.

    .EXAMPLE
       New-RandomPassword -MinPasswordLength 25 -MaxPasswordLength 35 -Count 5
       wMWyYwZniduxjNv%Y!Y5q2V348CVSPYNgY
       MTp6#Z!dCgk8s7eEZEc3yuC3Btfutzj
       hQiKh8nP4XfCTL7s%HTwTKgag9Gn#1&7
       djaWbAtfmapqy5vAASgJvC276XCf&
       %c3b6mBhSt3&CdR#9#Nk9Rc!%v4umGpQRQ

       Generates 5 passwords between 25 and 35 characters in length
    .OUTPUTS
       [String]
    .NOTES
       Written by Simon W�hlin, blog.simonw.se
       Augmented by Todd Lehmann, theosomos@gmail.com
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
#endregion Account-Management

#region Certificate
function New-EncryptionCertificate
{
     [CmdletBinding()]
     [OutputType([System.IO.FileInfo])]

     param
     (
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          # LiteralPath tofolder create certificatefile in
          [System.IO.DirectoryInfo]
          $OutputFolder = ((Get-Location).ToString())
          ,
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          [String]
          # Password for PFX file
          $CertificatePassword = $Script:CertPfxDefaultPassword
     )

     process
     {
          Write-Host ('{0} {1} - Start {0}' -f $Script:HeaderCharacters, $MyInvocation.MyCommand) -ForegroundColor Green
          Write-Host

          # note: These steps need to be performed in an Administrator PowerShell session
          #$cert = New-SelfSignedCertificate -Type DocumentEncryptionCertLegacyCsp -DnsName 'MdpEncryptionCetificate' -HashAlgorithm SHA256
          $cert = New-SelfSignedCertificate -Type DocumentEncryptionCert -DnsName $Script:CertDnsName -HashAlgorithm SHA256 -KeyUsage 'KeyEncipherment','DataEncipherment' -KeyUsageProperty All
          Write-Host ('Certificate object created:')
          ($cert | Select-Object -Property * | Out-String).Trim() | Out-Host

          # export the public key certificate
          $certFilePath = ([System.IO.FileInfo] (Join-Path -Path $OutputFolder.FullName -ChildPath ('{0}.pfx' -f $Script:CertDnsName)))
          Write-Host
          Write-Host ('Creating certificate file at ''{0}''' -f $certFilePath.FullName)

          $exportSecPwd = ConvertTo-SecureString -String $CertificatePassword -AsPlainText -Force
          $certFileObj = $cert | Export-PfxCertificate -FilePath $certFilePath -Password $exportSecPwd -Force
          $certFileObj.Refresh()

          if (-not ($certFileObj.Exists))
          {
               Write-Error ('Error creating certificate file ''{0}''' -f $certFilePath.FullName)
          }

          Write-Host
          Write-Host ('{0} {1} - End {0}' -f $Script:HeaderCharacters, $MyInvocation.MyCommand) -ForegroundColor Green
          return $certFileObj
     }
}

function Install-EncryptionCertificate
{
     [CmdletBinding()]
     [OutputType()]

     param
     (
          [Parameter(Mandatory = $true,
               ValueFromPipeline = $true)]
          [ValidateNotNullOrEmpty()]
          # LiteralPath to the certifcate file
          [System.IO.FileInfo]
          $LiteralPath
          ,
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          [String]
          # Password for PFX file
          $CertificatePassword = $Script:CertPfxDefaultPassword
     )

     process
     {
          Write-Host ('{0} {1} - Start {0}' -f $Script:HeaderCharacters, $MyInvocation.MyCommand) -ForegroundColor Green
          Write-Host

          $LiteralPath.Refresh()
          if (-not $LiteralPath.Exists)
          {
               throw (New-Object -TypeName System.IO.FileNotFoundException -ArgumentList ('Unable to locate certificate file at path ''{0}''' -f $LiteralPath.FullName))
          }

          Write-Host ('Installing Certificate ''{0}'' to ...' -f $LiteralPath.Name)
          $secCertPass = ConvertTo-SecureString -String $CertificatePassword -AsPlainText -Force

          Write-Host
          Write-Host ("`tCert:\CurrentUser\My")
          Import-PfxCertificate -FilePath $LiteralPath.FullName -CertStoreLocation Cert:\CurrentUser\My -Password $secCertPass -Exportable | Out-Host

          Write-Host
          Write-Host ("`tCert:\LocalMachine\My")
          Import-PfxCertificate -FilePath $LiteralPath.FullName -CertStoreLocation Cert:\LocalMachine\My -Password $secCertPass -Exportable | Out-Host
          Write-Host

          Write-Host ('''{0}'' Certficate Installed' -f $LiteralPath.BaseName)

          Write-Host ('Deleting sourcce pfx file')
          $LiteralPath.Refresh()
          if ($LiteralPath.Exists)
          {
               $LiteralPath.Delete()
          }

          Write-Host
          Write-Host ('{0} {1} - End {0}' -f $Script:HeaderCharacters, $MyInvocation.MyCommand) -ForegroundColor Green
     }
}
#endregion Certificate

#region Credential-Caching
function Get-CachedCredential
{
     PROCESS
     {
          Write-Output ($Script:CachedCredential)
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

function Remove-CachedCredential
{
     PROCESS
     {
          $Script:CachedCredential = [System.Management.Automation.PSCredential]::Empty
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
#endregion Credential-Caching


#region Credential-Storage
<#
     Account Object Properties
     * Username
     * Password
     * Domain
     * Description
     * DateSet
     * DateExpire
     * SetBy
     * Temporary
     * Environment
     * Owner
#>

function Add-Account
{
     [CmdletBinding()]
     [OutputType()]

     param
     (
          [Parameter(Mandatory = $true)]
          [ValidateNotNullOrEmpty()]
          # Username
          [String]
          $Username
          ,
          [Parameter(Mandatory = $true)]
          [ValidateNotNullOrEmpty()]
          # Password
          [String]
          $Password
          ,
          [Parameter(Mandatory = $true)]
          [ValidateNotNullOrEmpty()]
          # Domain the account authenticates. For example SQL, Azure, locally or an Active Directory domain
          [string]
          $Domain
          ,
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          # Environment credential is used in
          [String]
          $Environment
          ,
          [Parameter(Mandatory = $true)]
          [ValidateNotNullOrEmpty()]
          # Description of account
          [String]
          $Description
          ,
          [Parameter(Mandatory = $true)]
          [ValidateNotNullOrEmpty()]
          # Owner of the account
          [String]
          $Owner
          ,
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          # Date the account expires
          [DateTime]
          $ExpiresOn
          ,
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          [ValidateSet('Y','N')]
          # Indicates whether the account is temporary or not. If it is, it will be deleted on its expiration date
          [String]
          $Temporary = 'N'
     )

     process
     {
          $aObj = New-PsAccountObject
          $aObj.Username = $Username.ToLower()
          $aObj.Password = $Password
          $aObj.Domain = $Domain
          $aObj.Description = $Description
          $aObj.SetBy = $env:USERNAME.ToLower()
          $aObj.Temporary = $false
          $aObj.Environment = $Environment.ToUpper()
          $aObj.Owner = $Owner

          if ($PSBoundParameters.ContainsKey('Temporary'))
          {
               if ($Temporary -eq 'Y')
               {
                    $aObj.Temporary = $true
               }
               else
               {
                    $aObj.Temporary = $false
               }
          }

          Write-CredentialStorageFile -PsAccountObject $aObj
     }
}

function Get-AllAccounts
{
     [CmdletBinding()]
     [OutputType([PSCustomObject[]])]

     param()

     process
     {
          if (Test-CredentialStorageFile)
          {
               $eString = [string]::Empty
               try
               {
                    $eString = Get-Content -LiteralPath $Script:EncCredFileObj
               }
               catch
               {
                    throw $PSItem
               }
          }
     }
}
#endregion Credential-Storage

#region Encryption-Decryption
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

          return $cmsBase64String
     }
}
New-Alias -Name 'ConvertTo-EncryptedCredential' -Value 'Protect-Credential' -Scope "Global" -Force

function Protect-String
{
     [CmdletBinding()]
     [OutputType([String])]

     param
     (
          [Parameter(Mandatory = $true,
               ValueFromPipeline = $true)]
          [ValidateNotNullOrEmpty()]
          [String]
          # String to be in crypted
          $String
     )

     process
     {
          <#
          This cmdlet encrypts credential objects using the certificate created using the New-EncryptionCertificate command.
          You must have this certificate installed in order to encrypt/decrypt credentials.
          Use New-EncryptionCertificate and Install-EncryptionCertificate to install the certificate in your certificate store.
          To be clear, use New-EncryptionCertificate to generate the certificate, and then install that certificate on all machines
          where encryption/descryption will be done

          Inspired by: https://www.cgoosen.com/2016/05/using-a-certificate-to-encrypt-credentials-in-automated-powershell-scripts-an-update/
          #>

          $certPath = 'Cert:\LocalMachine\My'
          $Cert = Get-ChildItem -Path $certPath | Where-Object {$PSItem.Subject -match $Script:CertDnsName}

          if (-not $Cert)
          {
               throw (New-Object -TypeName System.InvalidOperationException -ArgumentList ('Cannot find a certificate in the local certificate store ''{0}'' that matches the name ''{1}''' -f $certPath,$Script:CertDnsName))
          }

          $cmsMessage = Protect-CmsMessage -To $Cert -Content $String
          $cmsByteArr = [System.Text.Encoding]::UTF8.GetBytes($cmsMessage)
          $cmsBase64String = [System.Convert]::ToBase64String($cmsByteArr)

          return $cmsBase64String
     }
}
New-Alias -Name 'ConvertTo-EncryptedString' -Scope "Global" -Force -Value 'Protect-String'

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
New-Alias -Name 'ConvertFrom-EncryptedCredential' -Value 'Unprotect-Credential' -Scope "Global" -Force

function Unprotect-SecureString
{
     [CmdletBinding()]
     [OutputType([String])]

     param
     (
          [Parameter(Mandatory = $true,
               ValueFromPipeline = $true)]
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
New-Alias -Name 'ConvertFrom-EncryptedString' -Scope "Global" -Force -Value 'Unprotect-String'

function Unprotect-String
{
     [CmdletBinding()]
     [OutputType([String])]

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
          This cmdlet encrypts credential objects using the certificate created using the New-EncryptionCertificate command.
          You must have this certificate installed in order to encrypt/decrypt credentials.
          Use New-EncryptionCertificate and Install-EncryptionCertificate to install the certificate in your certificate store.
          To be clear, use New-EncryptionCertificate to generate the certificate, and then install that certificate on all machines
          where encryption/descryption will be done

          Inspired by: https://www.cgoosen.com/2016/05/using-a-certificate-to-encrypt-credentials-in-automated-powershell-scripts-an-update/
          #>

          $certSearchString = '$Script:CertDnsName'
          $certPath = 'Cert:\LocalMachine\My'
          $Cert = Get-ChildItem -Path $certPath | Where-Object {$PSItem.Subject -match $Script:CertDnsName}

          if (-not $Cert)
          {
               throw (New-Object -TypeName System.InvalidOperationException -ArgumentList ('Cannot find a certificate in the local certificate store ''{0}'' that matches the name ''{1}''' -f $certPath,$Script:CertDnsName))
          }


          $encodedBytes = [System.Convert]::FromBase64String($EncryptedString)
          $decodedBlob = [System.Text.Encoding]::UTF8.GetString($encodedBytes)

          $decryptedString = Unprotect-CmsMessage -Content $decodedBlob -To $Cert.Thumbprint -IncludeContext

          Write-Output ($decryptedString) -NoEnumerate

     }
}
#endregion Encryption-Decryption

#endregion Public-Functions

#region Private-Functions
function New-PsAccountObject
{
     [CmdletBinding()]
     [OutputType([PSCustomObject])]

     param ( )

     process
     {
          <#
               Account Object Properties
               * Username
               * Password
               * Domain
               * Description
               * DateSet
               * DateExpire
               * SetBy
               * Temporary
               * Environment
               * Owner
          #>

          $obj = [PSCustomObject] @{
               Username    = [String]::Empty
               Password    = [String]::Empty
               Domain      = [String]::Empty
               Description = [String]::Empty
               DateLastSet = [DateTIme]::UtcNow
               DateExpires = ([DateTIme]::UtcNow.AddYears(1))
               SetBy       = [String]::Empty
               Temporary   = $false
               Environment = [String]::Empty
               Owner       = [String]::Empty
          }

          return $obj
     }
}

function Test-CredentialStorageFile
{
     [CmdletBinding()]
     [OutputType([Boolean])]

     param ()

     process
     {
          $fileExists = $false
          $Script:EncCredFileObj.Refresh()
          if ($Script:EncCredFileObj.Exists)
          {
               $fileExists = $true
          }

          Write-Output $fileExists
     }
}

function Write-CredentialStorageFile
{
     [CmdletBinding()]
     [OutputType([PSCustomObject[]])]

     param
     (
          [Parameter(Mandatory = $true,
               ValueFromPipeline = $true)]
          [ValidateNotNullOrEmpty()]
          # PsCredentialObject to be added to storage
          [PSCustomObject[]]
          $PsAccountObject
     )

     process
     {
          $rawFileContents = [String]::Empty
          $allAccounts = [PSCustomObject[]] @()
          if (Test-CredentialStorageFile)
          {
               $rawFileContents = (Get-Content -LiteralPath $Script:EncCredFileObj.FullName -Raw)
               $descryptString = Unprotect-String -EncryptedString $rawFileContents
               $allAccounts += ($descryptString | ConvertTo-Json)
          }

          $allAccounts += $PsAccountObject

          Write-Output ($allAccounts) -NoEnumerate
     }
}
#endregion Private-Functions