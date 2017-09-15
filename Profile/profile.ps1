
. "D:\Source\PoSh\Profile\Profile-Current.psm1"

if ($env:USERDOMAIN -ne $env:COMPUTERNAME)
{
     . "D:\Source\PoSh\Profile\Profile-Work.psm1"
}
