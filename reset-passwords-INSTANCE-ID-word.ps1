# https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/ec2launch.html
#reset windows administrator password for ec2 - get from console
#C:\ProgramData\Amazon\EC2-Windows\Launch\Scripts\InitializeInstance.ps1 -Schedule
$NEWPASS = (New-Object System.Net.WebClient).DownloadString("http://169.254.169.254/latest/meta-data/instance-id")
mysql  -uroot  -p"$NEWPASS"   --execute="SET PASSWORD FOR 'root'@'localhost' = PASSWORD('INSTANCE-ID');"
mysql  -uroot -p"INSTANCE-ID"  --execute="SET PASSWORD FOR 'hmail'@'localhost' = PASSWORD('INSTANCE-ID');"
mysql  -uroot -p"INSTANCE-ID"  --execute="SET PASSWORD FOR 'roundcube'@'localhost' = PASSWORD('INSTANCE-ID');"
$hm = New-Object -ComObject hMailServer.Application
$hm.Authenticate("Administrator","$NEWPASS")

$hm.Settings.SetAdministratorPassword("INSTANCE-ID")

copy "C:\Program Files (x86)\hMailServer\Bin\hMailServer-with-INSTANCE-ID-as-hashed-pass.ini" "C:\Program Files (x86)\hMailServer\Bin\hMailServer.INI"

Restart-Service -Name hMailServer -Force

rm "C:\Windows\Web\passwords-set-to-image-id"