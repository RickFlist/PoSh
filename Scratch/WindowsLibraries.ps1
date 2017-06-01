<#
Inspiration: https://www.petri.com/creating-custom-xml-in-powershell
#>

$libMsLocation = [System.IO.DirectoryInfo] 'C:\Users\RickFlist\AppData\Roaming\Microsoft\Windows\Libraries'

[Xml]$Doc = New-Object -TypeName System.Xml.XmlDocument
$dec = $doc.CreateXmlDeclaration("1.0","UTF-8",$null)
$Doc.AppendChild($dec)

$newXmlNs = $Doc.CreateElement("libraryDescription","xmlns","http://schemas.microsoft.com/windows/2009/library")
$Doc.AppendChild($newXmlNs)

$doc.CreateNode([System.Xml.XmlNo, "libraryDescription","http://schemas.microsoft.com/windows/2009/library")

$Doc.Normalize()
$Doc.Save('C:\Temp\temp.xml')