# https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/ec2launch.html
#reset windows administrator password for ec2 - get from console
#C:\ProgramData\Amazon\EC2-Windows\Launch\Scripts\InitializeInstance.ps1 -Schedule
Set-PSDebug -Trace 2; foreach ($i in 1..3) {$i}
$NEWPASS = (New-Object System.Net.WebClient).DownloadString("http://169.254.169.254/latest/meta-data/instance-id")
mysql  -uroot  -p"$NEWPASS"   --execute="SET PASSWORD FOR 'root'@'localhost' = PASSWORD('INSTANCE-ID');"
mysql  -uroot -p"INSTANCE-ID"  --execute="SET PASSWORD FOR 'hmail'@'localhost' = PASSWORD('INSTANCE-ID');"
mysql  -uroot -p"INSTANCE-ID"  --execute="SET PASSWORD FOR 'roundcube'@'localhost' = PASSWORD('INSTANCE-ID');"


$hm = New-Object -ComObject hMailServer.Application
$hm.Authenticate("Administrator","$NEWPASS")
$hm.Settings.SetAdministratorPassword("INSTANCE-ID")

###### REMOVE domain from hmailserver - DELETE certs from locations and clean databases, But leave roundcube initialized 
$maildomain = "mail.float.i.ng"
$hm = New-Object -ComObject hMailServer.Application
$hm.Authenticate("Administrator","INSTANCE-ID")

$Windows_SSLCert_Name = $maildomain

$hm.Settings.SSLCertificates.DeleteByDBID(0)
$hm.Settings.SSLCertificates.DeleteByDBID(1)
$hm.Settings.SSLCertificates.DeleteByDBID(2)
$hm.Settings.SSLCertificates.DeleteByDBID(3)
$hm.Settings.SSLCertificates.DeleteByDBID(4)
$hm.Settings.SSLCertificates.DeleteByDBID(5)

$hmDelDomain = $hm.Domains.Delete()


$hmDelDomain = $hm.Domains.DeleteByDBID(1)
$hmDelDomain = $hm.Domains.DeleteByDBID(0)

$hmDelDomain = $hm.Domains.DeleteByDBID(2)

$hmDelDomain = $hm.Domains.DeleteByDBID(3)


mysql  -uroot -p"INSTANCE-ID"  --execute="DELETE from hm_accounts"
mysql  -uroot -p"INSTANCE-ID"  --execute="DELETE from hm_domains"
mysql  -uroot -p"INSTANCE-ID"  --execute="DELETE from hm_sslcertificates"


del "c:\certs\*.*"

Remove-WebBinding -Name "Default Web Site" -IPAddress "*" -Port 443 -HostHeader "test.float.i.ng"
Remove-WebBinding -Name "Default Web Site" -IPAddress "*" -Port 443 -HostHeader "mail.float.i.ng"
Remove-WebBinding -Name "Default Web Site" -IPAddress "*" -Port 443 -HostHeader "hmail.float.i.ng"
Remove-WebBinding -Name "Default Web Site" -IPAddress "*" -Port 80 -HostHeader "test.float.i.ng"
Remove-WebBinding -Name "Default Web Site" -IPAddress "*" -Port 80 -HostHeader "mail.float.i.ng"
Remove-WebBinding -Name "Default Web Site" -IPAddress "*" -Port 80 -HostHeader "mail.float.i.ng"



copy "C:\Program Files (x86)\hMailServer\Bin\hMailServer-with-INSTANCE-ID-as-hashed-pass.ini" "C:\Program Files (x86)\hMailServer\Bin\hMailServer.INI"

Restart-Service -Name hMailServer -Force

rm "C:\Windows\Web\passwords-set-to-image-id"

# $hmAddDomain.Name = "$maildomain"
# $hmAddDomain.Active = $true
# $hmAddDomain.Save()
# $hm.Settings.HostName =  $maildomain
# $hm.Settings.HostName.Save

# $SSLCert_KEY_Private = "c:\certs\$maildomain-key.pem"
# $SSLCert_CRT_Public = "c:\certs\$maildomain-crt.pem"
# 
# $hm_SSLCert_New = $hm.Settings.SSLCertificates.Delete()
# $hm_SSLCert_New.Name = $Windows_SSLCert_Name
# $hm_SSLCert_New.PrivateKeyFile = $SSLCert_KEY_Private
# $hm_SSLCert_New.CertificateFile = $SSLCert_CRT_Public
# $hm_SSLCert_New.Save()
