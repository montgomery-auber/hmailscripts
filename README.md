# hmailscripts

The files here are for automating installation of Hmailserver on an Windows svr EC2 that already has Mysql or MariaDB, certbot, IIS, base hmailserver and php with fast cgi setup in the IIS, as well as Roundcube.<br>

The php.ini is required by roundcube. I am re-starting this project after wasting time with headhunters doing devops tests and interviews. As they suck all of your energy up, I stopped for about 4 months. I vaguely remember that I stopped with permission issue with Roundcube.<br>

install-password-set-hmail-roundcube.ps1 - sets the base password for stuff.<br>

set-domain-with-cert-iis-hmail.ps1 - This script I worked on really hard with lots of assistance from the folks at the Hmailserver community board. They are great folks, I wish the Linux folks would be as nice. I will mention them by name and handle later, when this becomes working. Anyway, this script configures your domain, so put your domain in place of mine at $maildomain towards the top of the file.<br> 

This repo expects a bunch of stuff to be pre-installed on the Windows EC2 server!<br>
- IIS
- FastCGI
- php
- mysql - Maria works too but needs some file copied from Oracle Mysql anyway 
- Rouncube unzippped as the root of IIS
- wacs - certbot script that installs the certs into IIS and creates cert files for hmail
- Hmailserver 
<br> 

It also needs the php.ini file in the correct place<br>
the hmail.ini files need to be C:\Program Files (x86)\hMailServer\Bin\ 

--

From Windows add remove programs it says
AWS ssm agent
aws pv drivers - I guess for network
aws tools for windows
hmailserver 5.6.8-B2574
IIS url rewrite module 2
maria DB 10.6 - next time use mysql
mirsosft visual C++ 2015-1019 Redistributable (x64) 14.29.3015
