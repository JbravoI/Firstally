# Random Password Generator

function Get-RandomCharacters($length, $characters) {
    $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length }
    $private:ofs = ""
    return [String]$characters[$random]
}
function Set-RandomCharacters([string]$inputString) {     
    $characterArray = $inputString.ToCharArray()   
    $scrambledStringArray = $characterArray | Get-Random -Count $characterArray.Length     
    $outputString = -join $scrambledStringArray
    return $outputString 
}

# Configure Password strength. Non-allowable characters: " ' ` / \ < % ~ | $ & !
$password = Get-RandomCharacters -length 5 -characters 'abcdefghiklmnoprstuvwxyz'
$password += Get-RandomCharacters -length 2 -characters 'ABCDEFGHKLMNOPRSTUVWXYZ'
$password += Get-RandomCharacters -length 3 -characters '1234567890'
$password += Get-RandomCharacters -length 2 -characters '@#*+'

$password = Set-RandomCharacters $password

$Bytes = [System.Text.Encoding]::Unicode.GetBytes($password)
$EncodedText = [Convert]::ToBase64String($Bytes)

# debug
# Write-Host 'plaintext Password:: '$password
# Write-Host 'encoded Password:: '$EncodedText

$DeploymentScriptOutputs = @{}
$DeploymentScriptOutputs['password'] = $password
$DeploymentScriptOutputs['encodedPassword'] = $EncodedText