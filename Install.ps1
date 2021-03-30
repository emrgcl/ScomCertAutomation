$Arguments = @('C:\Source\tools\ScomCertAutomation\Settings.psd1')
$FilePath = 'C:\Source\tools\ScomCertAutomation\ScomCertAutomation.ps1'
$JobName = 'ScomCertAutomation'
$TimeSpanHours = 8
$cred = Get-Credential
$trigger =New-JobTrigger -Once -At "03/29/2021 15:00:00" -RepetitionInterval (New-TimeSpan -Hours $TimeSpanHours ) -RepeatIndefinitely
Register-ScheduledJob -FilePath $FilePath -Name $JobName -Credential $cred -Trigger $trigger -ArgumentList $Arguments -Verbose