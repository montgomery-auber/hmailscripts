# https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/ec2launch.html
Set-PSDebug -Trace 2; foreach ($i in 1..3) {$i}
& "C:\ProgramData\Amazon\EC2-Windows\Launch\Scripts\InitializeInstance.ps1" -Schedule
sleep 1
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
$hmDelDomain = $hm.Domains.DeleteByDBID(4)
$hmDelDomain = $hm.Domains.DeleteByDBID(5)

mysql -D hmail -uroot -p"INSTANCE-ID"  --execute="DELETE from hm_accounts"
mysql -D hmail -uroot -p"INSTANCE-ID"  --execute="DELETE from hm_domains"
mysql -D hmail -uroot -p"INSTANCE-ID"  --execute="DELETE from hm_sslcertificates"

Unregister-ScheduledTask -TaskName  "win-acme renew (acme-v02.api.letsencrypt.org)" -Confirm:$false

Remove-Item "c:\certs\*.*" -Recurse
Remove-Item "C:\Program Files (x86)\hMailServer\Data\*.*" -Recurse
Remove-Item "C:\ProgramData\win-acme" -Recurse
Remove-Item "C:\Program Files (x86)\hMailServer\Logs\*" -Recurse
Remove-Item "C:\inetpub\logs\LogFiles\W3SVC1\*" -Recurse

Remove-WebBinding -Name "Default Web Site" -IPAddress "*" -Port 443 -HostHeader "test.float.i.ng"
Remove-WebBinding -Name "Default Web Site" -IPAddress "*" -Port 443 -HostHeader "mail.float.i.ng"
Remove-WebBinding -Name "Default Web Site" -IPAddress "*" -Port 443 -HostHeader "hmail.float.i.ng"
Remove-WebBinding -Name "Default Web Site" -IPAddress "*" -Port 80 -HostHeader "test.float.i.ng"
Remove-WebBinding -Name "Default Web Site" -IPAddress "*" -Port 80 -HostHeader "mail.float.i.ng"
Remove-WebBinding -Name "Default Web Site" -IPAddress "*" -Port 80 -HostHeader "mail.float.i.ng"

#put files with INSTANCE-ID 
copy "C:\Program Files (x86)\hMailServer\Bin\hMailServer-with-INSTANCE-ID-as-hashed-pass.ini" "C:\Program Files (x86)\hMailServer\Bin\hMailServer.INI"
copy "C:\inetpub\wwwroot\config\config-orig.inc.php" "C:\inetpub\wwwroot\config\config.inc.php"

Restart-Service -Name hMailServer -Force

Remove-Item "C:\Windows\Web\passwords-set-to-image-id"

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
