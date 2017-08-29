
. "D:\Source\PoSh\Profile\Profile-Current.ps1"

if ($env:USERDOMAIN -ne $env:COMPUTERNAME)
{
     . "D:\Source\PoSh\Profile\Profile-Work.ps1"
}
