function ConvertTo-YnabFormat
{
    [CmdletBinding()]

    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        # Absolute path to .CSV file
        $LiteralPath
    )

    process
    {
        <# YNAB column order
            Date
            Payee
            Category
            Memo
            Outflow
            Inflow
        #>

        <# Chase column order
            Details
            Posting Date
            Description
            Amount
            Type
            Balance
        #>

        try
        {
            $csvFile = Resolve-FullPath -Path $LiteralPath
        }
        catch
        {
            throw $PSItem
        }
        
        $chaseCsv = Import-Csv -LiteralPath $csvFile.FullName
        
        $retValue = New-Object -TypeName System.Collections.ArrayList

        foreach ($row in $chaseCsv)
        {
            if ($row.Type -eq 'DEPOSIT')
            {
                $obj = [PSCustomObject] @{
                    Date = $row.'Posting Date'
                    Payee = $row.Description
                    Category = $null
                    Memo = $null
                    Outflow = $null
                    Inflow = $row.Amount
                }

                $retValue.Add($obj) | Out-Null
            }
            else
            {
                $obj = [PSCustomObject] @{
                    Date = $row.'Posting Date'
                    Payee = $row.Description
                    Category = $null
                    Memo = $null
                    Outflow = $row.Amount
                    Inflow = $null
                }

                $retValue.Add($obj) | Out-Null
            }
        }

        $retValue | Export-Csv -LiteralPath (Join-Path -Path $csvFile.DirectoryName -ChildPath ('{0}-Converted.csv' -f $csvFile.BaseName)) -NoTypeInformation -Force
    }
}