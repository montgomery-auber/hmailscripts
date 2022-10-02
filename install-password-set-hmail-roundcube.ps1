Set-PSDebug -Trace 2; foreach ($i in 1..3) {$i}
# Windows PowerShell example to check 'If File Exists' 
$ChkFile = "C:\Windows\Web\passwords-set-to-image-id"
$FileExists = Test-Path $ChkFile 
If ($FileExists -eq $True) {
Write-Host "Script has already been run"
exit 1
}
Else {
$NEWPASS = (New-Object System.Net.WebClient).DownloadString("http://169.254.169.254/latest/meta-data/instance-id")
# the following hashes the password and makes it lowercase like hmail likes
$NEWPASSHASH = ([System.BitConverter]::ToString((New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider).ComputeHash((New-Object -TypeName System.Text.UTF8Encoding).GetBytes('$NEWPASS')))).Replace("-","")
$NEWPASSHASH = ($NEWPASSHASH.ToLower())
echo "NEWPASS is $NEWPASS"
echo "NEWPASSHASH is $NEWPASSHASH"
$hm = New-Object -ComObject hMailServer.Application
#$hm.Authenticate("Administrator","INSTANCE-ID")  | Out-Null
#This hash for "INSTANCE-ID" is AdministratorPassword=4b3004e6c847e30836afc2b1c18a8f98c3c98a5154c3fcd66172452d1419516a13688a
$hm.Authenticate("Administrator","INSTANCE-ID")
$dbpassblow = $hm.Utilities.BlowfishEncrypt($NEWPASS)
echo "dbpassblow is  $dbpassblow"
mysql  -uroot -pINSTANCE-ID --execute="SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$NEWPASS');"
mysql  -uroot -p"$NEWPASS"  --execute="SET PASSWORD FOR 'hmail'@'localhost' = PASSWORD('$NEWPASS');"
##ADD for roundcube
mysql  -uroot -p"$NEWPASS"  --execute="SET PASSWORD FOR 'roundcube'@'localhost' = PASSWORD('$NEWPASS');"
#use this instead of cat or sed

$content = [System.IO.File]::ReadAllText("C:\Program Files (x86)\hMailServer\Bin\hMailServer-orig.INI").Replace("BLOWFISH",$dbpassblow)
[System.IO.File]::WriteAllText("C:\Program Files (x86)\hMailServer\Bin\hMailServer.INI", $content)

#Put the following  after blow mysql password, since it edits the real ini file 
$hm.Settings.SetAdministratorPassword($NEWPASS)

#the following will be for roundcube
$content = [System.IO.File]::ReadAllText("C:\inetpub\wwwroot\config\config-orig.inc.php").Replace("INSTANCE-ID",$NEWPASS)
[System.IO.File]::WriteAllText("C:\inetpub\wwwroot\config\config.inc.php", $content)
Restart-Service -Name hMailServer -Force

New-Item -ItemType file "C:\Windows\Web\passwords-set-to-image-id" 
 Exit 0
}



# This script needs to set passwords for 
#mysql root
#mysql hmail 
#hmailserver admin
#roudncube too
# administrator - hmail 