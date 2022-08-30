# hmailscripts

The files here are for automating installation of Hmailserver on an Windows svr EC2 that already has Mysql or MariaDB, certbot, IIS, base hmailserver and php with fast cgi setup in the IIS, as well as Roundcube.<br>

The php.ini is required by roundcube. I am re-starting this project after wasting time with headhunters doing devops tests and interviews. As they suck all of your energy up, I stopped for about 4 months. I vaguely remember that I stopped with permission issue with Roundcube.<br>

install-password-set-hmail-roundcube.ps1 - sets the base password for stuff.<br>

set-domain-with-cert-iis-hmail.ps1 - This script I worked on really hard with lots of assistance from the folks at the Hmailserver community board. They are great folks, I wish the Linux folks would be as nice. I will mention them by name and handle later, when this becomes working. Anyway, this script configures your domain, so put your domain in place of mine at $maildomain towards the top of the file.<br> 
