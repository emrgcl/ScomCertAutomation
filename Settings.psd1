@{

GlobalSettings = @{

<# 
    run the following command to craete the encrypted string. The user who will run the script must run the below command on this computer.
    ConvertTo-SecureString -String 'PasswordHere'  -AsPlainText -Force  | ConvertFrom-SecureString
#>
EncryptedPassword = '01000000d08c9ddf0115d1118c7a00c04fc297eb01000000c6113201d1e26045a1c397ed4dcaa0220000000002000000000003660000c00000001000000062682737b693e284accc35a497453c720000000004800000a000000010000000ff460e4546491257e9a8e84a66992654100000009da6a9fcc48acbf6a4d6d692d53d41041400000047d8a4ac2c4ab28cc9f85c099ccb17729320f8f3'
WorkingPath = 'c:\Source\Temp'
PfxPath = 'C:\Source\certs'
TemplateOid = '1.3.6.1.4.1.311.21.8.14310150.6140980.3492019.13473623.6158040.96.10125317.9696650'
Config = '"rootca.contoso.local\myrootca"'
LogFilePath='C:\Source\Tools\ScomCertAutomation\ScomCertAutomation.log'
}

Servers = @(
'gw01.contosodmz.local'
'gw02.contosodmztest.local'
'gw03'
)

}