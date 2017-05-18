1..25 | ForEach-Object {
    if (($PSItem % 5) -eq 0)
    {
        Write-Host ('This is a Test ''{0}''' -f $PSItem)
    }
}