Set-PSDebug -Trace 2; foreach ($i in 1..3) {$i}
$maildomain = $args[0]
# "mail.float.i.ng"  ## ask question what domain ?
$mailaddress = "admin@$maildomain"
$NEWPASS = (New-Object System.Net.WebClient).DownloadString("http://169.254.169.254/latest/meta-data/instance-id")
#$NEWPASS = "INSTANCE-ID"
#Create default website port 80 
New-WebBinding -Name "Default Web Site" -IPAddress "*" -Port 80 -HostHeader "$maildomain"
cd "C:\Program Files\win-acme.v2.1.19.1142.x64"
.\wacs.exe --store certificatestore,pemfiles --pemfilespath c:\certs  --source manual --host $maildomain  --certificatestore My --installation iis --installationsiteid 1 --accepttos   --emailaddress $mailaddress 
Remove-WebBinding -Name "Default Web Site" -IPAddress "*" -Port 80 -HostHeader "$maildomain"
#NOT sure if it will be needed as wacs is supposed to do it
#New-WebBinding -Name "Default Web Site" -IPAddress "*" -Port 143 -HostHeader "$maildomain" -Protocol "https"
$hm = New-Object -ComObject hMailServer.Application
## remember to actually create  this user so letsencrypt can email
$hm.Authenticate("Administrator","$NEWPASS")  | Out-Null
$hmAddDomain = $hm.Domains.Add()
$hmAddDomain.Name = "$maildomain"
$hmAddDomain.Active = $true
$hmAddDomain.Save()
$hm.Settings.HostName =  $maildomain
$hm.Settings.HostName.Save
$Windows_SSLCert_Name = $maildomain
$SSLCert_KEY_Private = "c:\certs\$maildomain-key.pem"
$SSLCert_CRT_Public = "c:\certs\$maildomain-crt.pem"
$hm_SSLCert_New = $hm.Settings.SSLCertificates.Add()
$hm_SSLCert_New.Name = $Windows_SSLCert_Name
$hm_SSLCert_New.PrivateKeyFile = $SSLCert_KEY_Private
$hm_SSLCert_New.CertificateFile = $SSLCert_CRT_Public
$hm_SSLCert_New.Save()
$certid = mysql -ss -uroot -p"$NEWPASS" -D hmail --execute="select sslcertificateid  from hm_sslcertificates where sslcertificatename='$maildomain';"
# Add mailbox to domain
$maildomain = $hm.Domains.ItemByName($maildomain)
$hmAccount = $maildomain.Accounts.Add()
$hmAccount.Address = $mailaddress
$hmAccount.Password = "$NEWPASS"
$hmAccount.Active = $true
$hmAccount.MaxSize = 100
$hmAccount.Save()
$hMSAdminPass = $NEWPASS
$hMS = New-Object -COMObject hMailServer.Application
$hMS.Authenticate("Administrator", $hMSAdminPass) | Out-Null
<### Update/Add TCP/IP Ports ###>
<# Hashtable of port information #>
$PortArray = @{}
$PortArray['Port25'] = @{
	'Address' = '0.0.0.0'
	'Protocol' = 1
	'PortNumber' = 25
	'UseSSL' = $true
	'ConnectionSec' = 2
	'CertID' = $certid
}
$PortArray['Port110'] = @{
	'Address' = '0.0.0.0'
	'Protocol' = 3
	'PortNumber' = 110
	'UseSSL' = $True
	'ConnectionSec' = 3
	'CertID' = $certid
}
$PortArray['Port143'] = @{
	'Address' = '0.0.0.0'
	'Protocol' = 5
	'PortNumber' = 143
	'UseSSL' = $True
	'ConnectionSec' = 3
	'CertID' = $certid
}

$PortArray['Port587'] = @{
	'Address' = '0.0.0.0'
	'Protocol' = 1
	'PortNumber' = 587
	'UseSSL' = $True
	'ConnectionSec' = 3
	'CertID' = $certid
}
Function UpdateExistingTCPIPPort {
	Param([hashtable]$PortArray) 
	$Return = $False
	$IteratePorts = 0
	Do {
		$TCPIPPort = $hMS.Settings.TCPIPPorts.Item($IteratePorts)

		<# If address and port number match, then update the port with the new information #>
		If (($TCPIPPort.Address -eq $PortArray.Address) -and ($TCPIPPort.PortNumber -eq $PortArray.PortNumber)) {
			$TCPIPPort.Protocol = $PortArray.Protocol
			$TCPIPPort.PortNumber = $PortArray.PortNumber
			$TCPIPPort.SSLCertificateID = $PortArray.CertID
			$TCPIPPort.UseSSL = $PortArray.UseSSL
			$TCPIPPort.ConnectionSecurity = $PortArray.ConnectionSec
			$TCPIPPort.Save()
			$Return = $True
			Break
		}
		$IteratePorts++
	} Until ($IteratePorts -eq $hMS.Settings.TCPIPPorts.Count)
	Return $Return
}
<# Send all port hashtables to Function UpdateExistingTCPIPPort to either update with new info or reject as non-existent#>
ForEach ($Port In $PortArray.Keys){	
	<# If Function UpdateExistingTCPIPPort returns False due to non-existent port, then create new port with data from hashtable #>
	If (-not(UpdateExistingTCPIPPort -PortArray $PortArray[$Port])) {
		$TCPIPPort = $hMS.Settings.TCPIPPorts.Add()
		$TCPIPPort.Protocol = $PortArray[$Port].Protocol
		$TCPIPPort.PortNumber = $PortArray[$Port].PortNumber
		$TCPIPPort.SSLCertificateID = $PortArray[$Port].CertID
		$TCPIPPort.UseSSL = $PortArray[$Port].UseSSL
		$TCPIPPort.ConnectionSecurity = $PortArray[$Port].ConnectionSec
		$TCPIPPort.Save()
	}
} 
Restart-Service -Name hMailServer -Force 


#CONSIDER 443 forward from 80 - https://dbaland.wordpress.com/2019/02/13/create-a-http-to-https-url-redirect-in-iis-with-powershell/
