[CmdletBinding()]
Param(
[Parameter(Mandatory = $true)]
[ValidateScript({Test-PAth -Path $_})]
[string]$SettingsPath
)
Function New-PFXCertficate {
[CmdletBinding()]
Param(
[Parameter(Mandatory = $true)]
$Fqdn,
[Parameter(Mandatory = $true)]
$TempPath,
[Parameter(Mandatory = $true)]
$ExportPath,
[Parameter(Mandatory = $true)]
$PassWord,
[Parameter(Mandatory = $true)]
$TemplateOid,
[Parameter(Mandatory = $true)]
$Config 
)

$certinf = @"
[NewRequest]                                                 
Subject="CN=$Fqdn"                                       
KeyLength=2048
Exportable=TRUE                                             
KeySpec=1                                                    
KeyUsage=0xf0                                              
MachineKeySet=TRUE                                           
[RequestAttributes]
CertificateTemplate="$TemplateOid"
"@

$PathParent = "$TempPath\$(($fqdn -split '\.')[0])"
$InfPath = "$PathParent.inf"
$ReqPath = "$PathParent.req"
$CertPath = "$PathParent.cer"
$PfxPath = "$PathParent.pfx"
$RspPath = "$PathParent.rsp"


$certinf | Out-File -FilePath $InfPath 
$InfCreated = Test-Path -Path $InfPath

if($InfCreated) {

    Write-Log  "Created $InfPath"
    Certreq -new $InfPath $ReqPath | Out-Null

}
$ReqCreated = Test-path -Path $ReqPath
if ($ReqCreated) {
Write-Log  "Created $ReqPath"

Certreq -submit -Config $Config $ReqPath $CertPath | Out-Null

}
$CerCreated = Test-Path -Path $CertPath
If ($CerCreated) {

Write-Log  "Created $CertPath"
$ImportResult = certreq -accept $CertPath

Foreach ($Line in $ImportResult) {

if ($Line -match 'Thumbprint\:\s(?<Thumbprint>\S+)') {

$Thumbprint=$Matches['Thumbprint']

}
}

}

if ($Thumbprint){

    $Expression = "certutil -p $PassWord -exportpfx My $Thumbprint $PfxPath"
    Invoke-expression $Expression | Out-Null

    $PasswordMaskedExpression = "certutil -p xxx -exportpfx My $Thumbprint $PfxPath"
    Write-Log  "Invoking command: '$PasswordMaskedExpression'"

}

    $PfxCreated = Test-path -Path $PfxPath

if ((Test-path "Cert:\LocalMachine\my\$Thumbprint") -and $PfxCreated ) {
    
    Write-Log  "$PfxPath is created."

    Copy-Item $PfxPath -Destination $ExportPath -Force | Out-Null
    Get-Item -Path @($InfPath,$ReqPath,$CertPath,$PfxPath,$RspPath) -ErrorAction SilentlyContinue | Remove-Item -Force | Out-Null
    Remove-Item "Cert:\LocalMachine\my\$Thumbprint"

} else {

$ResultObject = [PscustombObject][Ordered]@{

    InfCreated = $InfCreated
    ReqCreated = $ReqCreated
    CerCreated = $CerCreated
    Thumbprint = $Thumbprint
    PfxCreated = $PfxCreated

}

Write-Log  $ResultObject
}
}

Function Get-PasswordText {
# decyrpt the password to be able to use in the certificate. password is protected by encryption.
[CmdLetBinding()]
Param(
    [Parameter(Mandatory =$true,ValueFromPipeline=$true)]
    [string]$EncryptedPassword
)
Process{

    $SecureString = $EncryptedPassword | ConvertTo-SecureString
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential('Nouser',$SecureString)
    ($Credential.GetNetworkCredential()).Password

}
}

Function New-ScriptPath {

[CmdletBinding()]
Param(

[Parameter(Mandatory = $true, ValueFromPipeLine = $true)]
[string[]]$Path

)
process {

Foreach ($Folder in $Path) {

    if (-not (Test-Path -Path $Folder)) {

        mkdir $Path | Out-Null

    }
}
}
}

Function Write-Log {

    [CmdletBinding()]
    Param(
    
    [Parameter(Mandatory = $True)]
    [string]$Message,
    [string]$LogFilePath = "$($env:TEMP)\log_$((New-Guid).Guid).txt"
    
    )
    
    $LogFilePath = if ($Script:LogFilePath) {$Script:LogFilePath} else {$LogFilePath}
    
    $Log = "[$(Get-Date -Format G)][$((Get-PSCallStack)[1].Command)] $Message"
    
    Write-verbose $Log
    $Log | Out-File -FilePath $LogFilePath -Append -Force
    
}



#region ScriptMain

$ScriptStart = Get-Date

Try {

    $Settings =  Import-PowerShellDataFile -Path $SettingsPath -ErrorAction Stop
    $Servers = $Settings.Servers
    $Password = $Settings.GlobalSettings.EncryptedPassword | Get-PasswordText -ErrorAction Stop
    $LogFilePath = $Settings.GlobalSettings.LogFilePath
    Write-Log "Script Started"
    New-ScriptPath -Path $Settings.GlobalSettings.WorkingPath,$Settings.GlobalSettings.PfxPath -ErrorAction Stop

}
Catch {

Throw $_

}


Foreach ($Server in $Servers) {

$ServerNetbiosName = ($Server -split '\.')[0]


$Parameters = @{

    Fqdn = $Server
    TempPath  = $Settings.GlobalSettings.WorkingPath
    ExportPath = $Settings.GlobalSettings.PfxPath
    Password = $Password
    TemplateOid = $Settings.GlobalSettings.TemplateOid
    Config = $Settings.GlobalSettings.Config

}

$ServerPfxPath = "$($Parameters.ExportPath)\$ServerNetbiosName.pfx"
$PfxExists = Test-path -Path $ServerPfxPath
if (-not $PfxExists) {

    Write-Log "Creating pfx for $Server on $ServerPfxPath"
    New-PFXCertficate @Parameters
    

} else {

    Write-Log "Found $ServerPfxPath skipping pfx creation for $Server"

}

}

$ScriptDurationSeconds = [Math]::Round(((Get-Date) - $ScriptStart).TotalSeconds)
Write-Log "Script Ended. Duration $ScriptDurationSeconds seconds."

#endregion
