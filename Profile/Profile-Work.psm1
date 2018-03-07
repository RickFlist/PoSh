#region Script-Variables
#endregion Script-Variables

#region Functions

function Register-RmProfile
{
     [CmdletBinding()]
     param
     (
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          [ValidateSet('MAXLAB R&D EXT 1','MAXLAB R&D EXT 2','MAXLAB R&D INT 1','MAXLAB R&D INT 2','MAXLAB R&D Primary','MAXLAB R&D Sandbox','MAXLAB R&D Self Service')]
          # Subscription to deploy to
          [String]
          $DefaultSubscriptionName = 'Office CPub ContentQA'
          ,
          [Parameter()]
          [Switch]
          # For re-authentication of Azure account
          $Force
     )

     process
     {
          try
          {
               Import-Module AzureRM.profile -Force -Global

               $profPath = [System.IO.FileInfo] (Join-Path -Path $env:APPDATA -ChildPath ('AzureProfiles\AzProfile-{0}.json' -f $env:USERNAME))
               if (-not (Test-Path -LiteralPath $profPath.Directory.FullName -PathType Container))
               {
                    $profPath.Directory.Create() | Out-Null
               }

               $profPath.Refresh()

               if ($Force.IsPresent)
               {
                    $rmProfile = Login-AzureRmAccount -SubscriptionName $DefaultSubscriptionName

                    $profPath.Refresh()
                    if ($profPath.Exists)
                    {
                         Remove-Item -LiteralPath $profPath.FullName -Force
                    }

                    Save-AzureRmContext -Profile $rmProfile -Path $profPath -Force
               }
               else
               {
                    $profPath.Refresh()
                    if (-not $profPath.Exists)
                    {
                         $rmProfile = Login-AzureRmAccount -SubscriptionName $DefaultSubscriptionName
                         Save-AzureRmContext -Profile $rmProfile -Path $profPath -Force
                    }
               }

               $azContext = Import-AzureRmContext -Path $profPath
               Microsoft.PowerShell.Utility\Write-Host ('Authenticated to "{0}" as "{1}" account. Current subscription is "{2}"' -f $azContext.Context.Environment.Name,$azContext.Context.Account.Id,$azContext.Context.Subscription.Name)
          }
          catch
          {
               throw ($PSItem)
          }


     }
}

function Save-RmProfile
{
     [CmdletBinding()]
     [OutputType()]

     param
     (
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          # PSProfile objecting containing cachable authentication infomration
          [Microsoft.Azure.Commands.Profile.Models.PSAzureProfile]
          $AzureProfile
     )

     process
     {
          if ( -not $PSBoundParameters.ContainsKey('AzureProfile') )
          {
               $AzureProfile = ( Login-AzureRmAccount )
          }

          $profPath = [System.IO.FileInfo] (Join-Path -Path $env:APPDATA -ChildPath ('AzureProfiles\AzProfile-{0}.json' -f $env:USERNAME))
          if (-not (Test-Path -LiteralPath $profPath.Directory.FullName -PathType Container))
          {
               $profPath.Directory.Create() | Out-Null
          }

          try
          {
               $null = Save-AzureRmContext -Profile $AzureProfile -Path $profPath -Force
          }
          catch
          {
               throw ($PSItem)
          }

          Write-Host ('Azure profile for "{0}" saved to "{1}"' -f $AzureProfile.Context.Account.Id,$profPath.FullName  )
     }
}
#endregion Functions

#region Execution

# Register-RmProfile

## Set aliases

#endregion Execution