#!/bin/sh
# cpanel-functions.sh
# common functions

# getrelease
# gets the relase of the distribution
# sets:
#   DIST        - The distro (redhat/centos/fedora)
#   DISTVER     - The distro version
#   DISTVERMAJ  - The major part of the distro version 
#   DISTVERMIN  - The minor part of the distro version
function getrelease {
	RHTEMP=`cat /etc/redhat-release | awk '{ print $1 }'`
	if [ $RHTEMP = "Red" ]; then
		AWKROW="5";
		DIST="redhat";
	elif [ $RHTEMP = 'CentOS' ]; then
		AWKROW="3"
		DIST="centos"
	else
		AWKROW="4";
		DIST="fedora";
	fi
	DISTVER=`cat /etc/redhat-release | awk "{ print \\$$AWKROW }"`
	if [ $DISTVER = "7.2" ]; then
		DISTVER="7.3";
	fi
	TEST=`echo $DISTVER | grep '\.'`
	if [ -n "$TEST" ]; then
		DISTVERMAJ=`echo $DISTVER | awk -F. "{print \\$1}"`
		DISTVERMIN=`echo $DISTVER | awk -F. "{print \\$1}"`
	else
		DISTVERMAJ=$DISTVER
		DISTVERMIN=0
	fi
}

# get_server_data
# Gets hostname and password
# sets:
#   MAINIP      - Gets IP Address from eth0
#   NETMASK     - Netmask of eth0
#   GATEWAY     - Gateway for networking
#   HOSTNAME    - What the hostname should be 
#   ROOTPW      - What the root password will be 
#   INITADMIN   - Do we install ServerSecure?
#   FANTASTICO  - Do we install fantastico?
#   BACKUPS     - Do we configure backups for this server

function get_server_data() {
   MAINIP=`ifconfig eth0 |grep "inet addr" | cut -d ":" -f 2 | cut -d " " -f 1`
   NETMASK=`ifconfig eth0 |grep "Mask:" | cut -d ":" -f 4`
   GATEWAY=`route -n | tail -1 | awk {'print $2'}`
	HOSTNAME=`hostname`

	echo -n "Enter Server's Billing UID: "
	read LPUID
	echo $LPUID > /home/temp/lp-UID

   echo -n "Root Password? "
   read ROOTPW

   echo -n "Does this server need ServerSecure? "
   read INITADMIN

   if [ "$INITADMIN" == "y" -o "$INITADMIN" == "Y" -o "$INITADMIN" == "yes" -o "$INITADMIN" == "Yes" -o "$INITADMIN" == "YES" ]; then
      INITADMIN=yes

   echo -n "Does this server need ServerSecure Plus? "
   read SECPLUS

   if [ "$SECPLUS" == "y" -o "$SECPLUS" == "Y" -o "$SECPLUS" == "yes" -o "$SECPLUS" == "Yes" -o "$SECPLUS" == "YES" ]; then
      SECPLUS=yes

   echo "Please specify the sshuser's password (also, please note the su user and the password you set in billing.)"
   read sshuserpass
   else
      SECPLUS=""
   fi
   else
      INITADMIN=""
   fi

   echo -n "Does this server need Fantastico? "
   read FANTASTICO
   if [ "$FANTASTICO" == "y" -o "$FANTASTICO" == "Y" -o "$FANTASTICO" == "yes" -o "$FANTASTICO" == "Yes" -o "$FANTASTICO" == "YES" ]; then
      FANTASTICO=yes
   else
      	FANTASTICO=""
   fi
		
	echo -n "Does this server need Softaculous? "

   read SOFTAC

   if [ "$SOFTAC" == "y" -o "$SOFTAC" == "Y" -o "$SOFTAC" == "yes" -o "$SOFTAC" == "Yes" -o "$SOFTAC" == "YES" ]; then
      SOFTAC=yes
   else
      SOFTAC=""
   fi

   echo -n "Configure backups? (This will not harm any data on the drive.) "
   read BACKUPS
   if [ "$BACKUPS" == "y" -o "$BACKUPS" == "Y" -o "$BACKUPS" == "yes" -o "$BACKUPS" == "Yes" -o "$BACKUPS" == "YES" ]; then
      BACKUPS=yes
   else
      BACKUPS=""
   fi
}

function set_resolver() {
# 10.10.10.10 is available to every DC
cat << EOF > /etc/resolv.conf
nameserver 10.10.10.10
EOF
}

# set_root_passwd
# Sets the root password from $ROOTPW
function set_root_passwd() {
	echo $ROOTPW | passwd --stdin root
}

#install_secplus
#installs serversecureplus
install_secplus() {
        if [ -f /usr/local/lp/configs/yum/yum.conf ] ; then
                yum -c /usr/local/lp/configs/yum/yum.conf -y install yumconf-serversecureplus
                yum -c /usr/local/lp/configs/yum/yum.conf -y install lp-modsec2-rules
        else
                yum -y install yumconf-serversecureplus
                yum -y install lp-modsec2-rules
        fi

        yum -y install serversecureplus-modsec2-rules serversecureplus-config
cat << EOF > /etc/csf/csf.allow
# Monitoring servers (MySQL ports only)
tcp:in:d=3306:s=10.20.9.0/24
tcp:in:d=3306:s=10.30.9.0/24
tcp:in:d=3306:s=209.59.139.14
tcp:in:d=3306:s=67.227.128.125
tcp:in:d=3306:s=67.227.128.126
tcp:in:d=3306:s=69.16.234.107
tcp:in:d=3306:s=69.16.234.108
tcp:in:d=3306:s=69.16.234.118
tcp:in:d=3306:s=69.16.234.119
tcp:in:d=3306:s=69.16.234.122
tcp:in:d=3306:s=69.16.234.123
tcp:in:d=3306:s=69.16.234.124
tcp:in:d=3306:s=69.16.234.125
tcp:in:d=3306:s=69.16.234.126

10.30.9.0/24
10.20.9.0/24
10.40.11.0/28
209.59.139.14
69.16.234.126
69.16.234.125
69.16.234.124
69.16.234.123
69.16.234.122
69.16.234.119
69.16.234.118
69.16.234.107 
69.16.234.108 
67.227.128.126
67.227.128.125


# LiquidWeb, added by ServerSecure Plus installer
#DC1 office range:
64.91.239.0/26
#DC2 office range
69.16.222.0/23
69.16.223.0/23
#Dc3 office ranges:
10.30.4.0/22
69.167.130.9
69.167.130.11
69.167.130.12
69.167.130.13
69.167.129.192/28
#SysEng range:
10.30.104.0/24
#QA Range:
10.30.2.128/25
#Backup Server Range
10.2.0.1/24
#DNS resolvers
209.59.157.254
69.167.128.254 

10.10.10.10
10.254.254.254
EOF

/etc/init.d/csf restart

echo $sshuserpass | passwd --stdin sshuser
}

# Sets the configuration for the network
function configure_ips() {
	OCTET1=`echo $MAINIP | cut -d "." -f 1`
	OCTET2=`echo $MAINIP | cut -d "." -f 2`
	OCTET3=`echo $MAINIP | cut -d "." -f 3`
	OCTET4=`echo $MAINIP | cut -d "." -f 4`

	#add extra IP - normally we assign these sequentially
	cat << EOF > /etc/ips
$OCTET1.$OCTET2.$OCTET3.`expr $OCTET4 + 1`:$NETMASK:$OCTET1.$OCTET2.$OCTET3.255
EOF

## Rebuild the IP pool
if [ -f /etc/init.d/ipaliases ]; then
	/etc/init.d/ipaliases restart
fi
}

# disable_recursion
# Disalbes recursion for everybody but monitoring servers (Cpanel only for now)
function disable_recursion() {
cp /etc/named.conf /etc/named.conf.bak
cat << EOF > /etc/named.conf
key "rndc-key" {
        algorithm hmac-md5;
        secret "";
};

controls {
    inet 127.0.0.1 allow { localhost; } keys { "rndc-key"; };
};
zone "." {
        type hint;
        file "/var/named/named.ca";
};

acl "trusted" {
127.0.0.1;
209.59.139.14;
69.16.234.126;
69.16.234.125;
69.16.234.124;
69.16.234.123;
69.16.234.122;
69.16.234.118;
69.16.234.119;
69.16.234.107;
69.16.234.108;
67.227.128.126;
67.227.128.125;
10.20.9.0/24;
10.30.9.0/24;
};

options {
   allow-recursion { trusted; };
};
EOF
}

# fix_hosts
# Sets /etc/hosts
function fix_hosts() {
	shortname=`echo ${HOSTNAME} | cut -d "." -f 1`
	cat << EOF > /etc/hosts
# Do not remove the following line, or various programs
# that require network functionality will fail.
127.0.0.1      ${shortname} ${HOSTNAME} localhost.localdomain localhost
${MAINIP}      ${shortname} ${HOSTNAME}
EOF
}

# install_modevasive
# Installsl mod_evasive
function install_modevasive() {
	cd /home/temp
	wget http://layer3.liquidweb.com/packages/mod_evasive_1.10.1.tar.gz
	tar xzf mod_evasive_1.10.1.tar.gz
	cd mod_evasive
	# TODO Alter for standard paths if this is in "Core"
	/usr/local/apache/bin/apxs -cia mod_evasive20.c
	cat << EOF > /usr/local/apache/conf/includes/pre_virtualhost_global.conf
<IfModule mod_evasive20.c>
DOSHashTableSize    6151
DOSPageCount        4
DOSSiteCount        100
DOSPageInterval     1
DOSSiteInterval     1
DOSBlockingPeriod   10
</IfModule>
EOF
	/usr/local/cpanel/bin/apache_conf_distiller --update 
	/usr/local/cpanel/bin/build_apache_conf 
}


# install_fantastico 
# Installs fantastico and Xcontroller (Cpanel only)
function install_fantastico {
	cd /usr/local/cpanel/whostmgr/docroot/cgi
	wget -N http://layer3.liquidweb.com/fantastico-files/fantastico_whm_admin.tgz
	tar xzpf fantastico_whm_admin.tgz
	rm -fv fantastico_whm_admin.tgz

	# Xcontroller
	cd /usr/local/cpanel/base/frontend
	rm -rf xcontroller
	rm -f xcontroller.tgz
	wget http://layer3.liquidweb.com/fantastico-files/xcontroller.tgz
	tar xzpf xcontroller.tgz
	chown -R root.root xcontroller/
	rm -f xcontroller.tgz
	# cachelangfiles is depreciated. build_locale_databases is the new file to call
	#/usr/local/cpanel/bin/cachelangfiles
	/usr/local/cpanel/bin/build_locale_databases
	cd /usr/local/cpanel/lang
	touch catalan french indonesian polish romanian spanish german italian portugues russian turkish
}

#install_softaculous
#Installs softaculous via the three lines that are in the wiki at https://wiki.int.liquidweb.com/articles/Softaculous 
function install_softaculous() {
(
/scripts/makecpphp
cd /usr/local/cpanel/whostmgr/docroot/cgi
wget -N http://www.softaculous.com/ins/addon_softaculous.php
chmod 755 addon_softaculous.php
/usr/local/cpanel/3rdparty/bin/php /usr/local/cpanel/whostmgr/docroot/cgi/addon_softaculous.php
/usr/local/cpanel/3rdparty/bin/php /usr/local/cpanel/whostmgr/docroot/cgi/softaculous/cron.php
cd /root/
) | tee -a /root/softaculous.log
}


# Configure backup scripts
function configure_cpanel_backups {
	cat << EOF > /etc/cpbackup.conf
BACKUP2 yes
BACKUPACCTS yes
BACKUPCHECK yes
BACKUPDAYS 0,1,2,3,4,5,6
BACKUPDIR /backup
BACKUPENABLE yes
BACKUPFILES no
BACKUPFTPDIR 
BACKUPFTPHOST 
BACKUPFTPPASS 
BACKUPFTPPASSIVE no
BACKUPFTPUSER 
BACKUPINC no
BACKUPINT daily
BACKUPLOGS no
BACKUPMOUNT no
BACKUPRETDAILY 0
BACKUPRETMONTHLY 1
BACKUPRETWEEKLY 1
BACKUPTYPE normal
DIEIFNOTMOUNTED no
GZIPRSYNCOPTS --rsyncable
MYSQLBACKUP both
EOF

	cat << EOF > /etc/cpbackup.public.conf
BACKUPENABLE yes
BACKUPTYPE normal
EOF
}

# disable_binaries
# Allows only root to run binaries that are often used in exploits.
function disable_binaries() {
	files="wget curl ps pstree w who whoami last"
	for file in $files; do
		chmod 700 `which $file`
		chown root:root `which $file`
	done
}

# install_headers
# Installs knernel headers via yum
function install_headers() {
yum -y install kernel-headers kernel-devel 
}

function install_glibc_devel () {
yum -y install glibc-devel
}

#
# alter_bash
# Make changes to bash (prompt, timed history, etc)
# 
# updates bashrc for bash_eternal history (courtesy of bcathey@liquidweb.com)
#
# will need to add if statement for CentOS 4 version for bash eternal setup,
# as syntax is similar but different
#

function alter_bash() {
        # Enable time stamps for bash history
        echo >> /etc/profile
        echo "HISTTIMEFORMAT=\"%Y%m%d - %H:%M:%S - \"" >> /etc/profile

        # Set bash prompt to show host name
        cat << EOF >> /root/.bashrc

# Set prompt
PS1="[\u@\`hostname\`] \W >> "
PS2=">"

# grep using color option
alias grep="grep --color"

# Custom prompt function 
function prm1 {
PS1="[\u@\h \w]# "

EOF

        if [ "$INITADMIN" ]; then

        cat << EOF >> /root/.bashrc

        echo "\$(mytty=\$(tty | sed 's/\/dev\///'); who|grep "\$mytty" | awk '{print \$1, \$2, \$5}')" "\$(history 1)" >> /usr/local/lp/bash_eternal_history

   }
PROMPT_COMMAND=prm1
EOF

        else

        cat << EOF >> /root/.bashrc

         echo "\$(mytty=\$(tty | sed 's/\/dev\///'); who|grep "\$mytty" | awk '{print \$1, \$2, \$5}')" "\$(history 1)" >> ~/.bash_eternal_history

    }
PROMPT_COMMAND=prm1
EOF
fi
#   readonly PROMPT_COMMAND=prm1   
}


# install_lpskel
# Installs our skeleton rpm, and repo files
function install_lpskel {
	cd /home/temp
	wget http://syspackages.sourcedns.com/packages/stable/centos/6/noarch/yumconf-sourcedns-1.0-3.noarch.rpm
	rpm -i yumconf-sourcedns-1.0-3.noarch.rpm
}

# install_ntp
# installs and configures ntp
function install_ntp() {
	getrelease
	yum -y install ntpd
	if [ "$DIST" == "centos" -a "$DISTVERMAJ" -gt 4 ]; then
		sed -i -e "s/server\ 0\.centos\.pool\.ntp\.org/server\ time\.liquidweb\.com/" /etc/ntp.conf
	else
		sed -i -e "s/server\ 0\.pool\.ntp\.org/server\ time\.liquidweb\.com/" /etc/ntp.conf
	fi
	service ntpd start
	chkconfig ntpd on
}

# set_syncookies
# Sets TCP syncookies
function set_syncookies() {
	echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.conf
	echo 1 > /proc/sys/net/ipv4/tcp_syncookies
}

# fix_logrotate
# Fixes log rotate configuration file
function fix_logrotate() {
	cat << EOF > /etc/cron.daily/logrotate
#!/bin/sh

export TMPDIR=/home/temp

/usr/sbin/logrotate /etc/logrotate.conf
EXITVALUE=\$?
if [ \$EXITVALUE != 0 ]; then
    /usr/bin/logger -t logrotate "ALERT exited abnormally with [\$EXITVALUE]"
fi
exit 0
EOF

}

# update_cpanel_settings
# Set the latest configs for cpanel
function update_cpanel_settings() {
	# Enable Cpanel automatic updates
	cat << EOF > /etc/cpupdate.conf
BANDMINUP=inherit
COURIERUP=inherit
CPANEL=release
EXIMUP=inherit
FTPUP=inherit
MYSQLUP=inherit
PYTHONUP=inherit
RPMUP=daily
SYSUP=daily
EOF

	# Change WHM Settings
	cat << EOF > /etc/wwwacct.conf
CONTACTEMAIL devnull@sourcedns.com
CONTACTPAGER devnull@sourcedns.com
ADDR $MAINIP
DEFMOD x3
ETHDEV eth0
FTPTYPE pureftpd
HOMEDIR /home
HOMEMATCH home
HOST $HOSTNAME
LOGSTYLE combined
NS ns1.`echo $HOSTNAME | cut -d "." -f 2-3`
NS2 ns2.`echo $HOSTNAME | cut -d "." -f 2-3`
SCRIPTALIAS y
EOF

	# Tweak Cpanel Settings
	rm -f /var/cpanel/cpanel.config
	rm -f /var/cpanel/cpanel.config.cache
	wget -P /var/cpanel http://layer3.liquidweb.com/configs/cpanel/cpanel.config

	# Update chksrvd settings
	echo -e "antirelayd:1\ncpsrvd:1\nentropychat:0\nexim:1\neximstats:0\nftpd:1\nhttpd:1\nimap:1\ninterchange:0\nmysql:1\nnamed:1\npop:1\nspamd:1" > /etc/chkserv.d/chkservd.conf
	/etc/init.d/chkservd restart
}

# install_raider
function install_raider() {
	# Raid monitoring has moved to raider
	yum -c /usr/local/lp/configs/yum/yum.conf -y install raider
	rm -f /usr/local/lp/var/raider/jobs/*
	/usr/local/lp/apps/raider get-devices
	/usr/local/lp/apps/raider run-jobs
}

# fix_bind
# Turns off recursion for everyone but monitoring servers.
function fix_bind() {
	disable_recursion
	service named restart
	chkconfig named on
	/scripts/fixndc
}

# fix_ssh
# Adjusts default ssh/d configuration
function fix_ssh() {
	# Fix SSH options
	rm -f /etc/ssh/sshd_config
	wget -P /etc/ssh/ http://layer3.liquidweb.com/configs/ssh/sshd_config
	service sshd restart
}

# fix_ftp
# adjust ftp
function fix_ftp() {
	/etc/init.d/pure-ftpd start
	chkconfig --level 345 pure-ftpd on
}

# Install Mr. Radar / mm3k rpms / sonarpush
function install_mrradar() {
	echo "Installing Mr. Radar Sonar Push..."
	TMPHASCPANEL=$1
	mv /home/temp/lp-UID /usr/local/lp/etc/lp-UID
	/usr/bin/yum -y install sonarpush
}

# move_domlogs
# Moves the domlogs to /home
function move_domlogs() {
	rm -rf /usr/local/apache/domlogs
	mkdir /home/domlogs
	ln -sf /home/domlogs /usr/local/apache/domlogs
}

# fix_cpanel_license
# Adds a cron entry to fix cpanel license issues
function fix_cpanel_license() {
	echo -e "0\t*/8\t*\t*\t*\t/usr/local/cpanel/cpkeyclt" >> /var/spool/cron/root
}

# install_mytop
# Installs mytop
function install_mytop() {
	# Mytop is not working yet due to a missing packing in our tree.
   /usr/bin/yum install -y lp-mytop
   echo "delay=2" >> /root/.mytop
}

# cron_yum
# Install a nightly yum update in cron
function cron_yum() {
  FILE=$(mktemp /tmp/temp.cronXXXXXXXX)
  crontab -u root -l > $FILE
  GREP=$(/bin/grep "/usr/bin/yum -y update" $FILE)
  if [ -z "$GREP" ]; then
    MIN=$[$RANDOM % 60]
    HOUR=$[$RANDOM % 3]
    echo "$MIN $HOUR * * * /usr/bin/yum -y update" >> $FILE
    crontab -u root $FILE
  fi
}

# activate_cpanel_pro
# Activates CPanel Pro
#   MAINIP must be set, call get_data before this.
function activate_cpanel_pro() {
	curl http://pro.cpanel.net/activate/index.cgi?ip=${MAINIP}
	/usr/local/cpanel/cpkeyclt
}

# configure_clam
# Configures the clam files.  (CPanel Only right now)
function configure_clam() {
   echo clamavconnector >> /var/cpanel/addonmodules
	cat > /etc/cpclamav.conf << EOF
DEFAULTSCANS=mail
EOF
}

# configure_exim
# Configures exim (CPanel Only right now)
function configure_exim() {
   cat > /etc/exim.conf.local << EOF
@AUTH@

@BEGINACL@

@CONFIG@
log_selector = +all
@DIRECTOREND@

@DIRECTORMIDDLE@

@DIRECTORSTART@

@ENDACL@

@RETRYEND@

@RETRYSTART@

@REWRITE@

@ROUTEREND@

@ROUTERSTART@

@TRANSPORTEND@

@TRANSPORTMIDDLE@

@TRANSPORTSTART@

EOF

   # Update Exim settings
   #
   wget -P /etc/ http://layer3.liquidweb.com/configs/exim/exim.conf.localopts
   /scripts/buildeximconf
   /etc/init.d/exim restart
}

# fix_courier
# updates courier to create courier config file. Otherwise pop3 and imap are down after post install completes
# creates /var/cpanel/courierconfig.yaml file by running script
function fix_courier() {
   /usr/local/cpanel/scripts/setupmailserver --force courier
}

# fix_clam
# Fixes clam if needed
function fix_clam() {	
	ARCH=`uname -i`
   	ls -l /usr/sbin/clamd > /dev/null 2&>1
   	if [ $? != 0 ]; then
      		echo "ClamAV connector missing, installing."
		if [ "$ARCH" = "x86_64" ]; then
			/usr/local/cpanel/modules-install/clamavconnector-Linux-x86_64/install
                	/etc/init.d/exim restart
		else
      			/usr/local/cpanel/modules-install/clamavconnector-Linux-i686/install
      			/etc/init.d/exim restart
		fi
   	fi
}

# whm_lic_agree
# Agree to WHM License Agreement
function whm_lic_agree() {
	touch /etc/.whostmgrft
	mkdir /var/cpanel/activate
#	touch /var/cpanel/activate/1.1
   touch /var/cpanel/activate/1.2
}

# fix_cpanel_ssl
# Fixes cpanel ssl
function fix_cpanel_ssl() {
	/scripts/rebuildcpanelsslcrt
	cd /var/cpanel/ssl/cpanel && ln -s /usr/local/cpanel/etc/cpanel.pem .
	service cpanel restart
}

# update_mysql
# Updates mysql to the 5.0 branch (CPanel Only right now)
function update_mysql() {
	echo "Running mysql update..."
	sed -i -e "s/mysql-version=4\.1/mysql-version=5\.0/" /var/cpanel/cpanel.config > /etc/my.cnf && /scripts/mysqlup
	wget -O /etc/my.cnf http://layer3.liquidweb.com/configs/mysql/my.cnf
	rm -f /var/lib/mysql/ib_logfile* && /etc/init.d/mysql restart
}

#start_mysql_core
#This starts mysql for the first time on a core managed server, used in conjuction with the below script of setting the mysql root password.
function start_mysql_core() {
	/etc/init.d/mysqld start
}

#mysql_root_password
#Generates a random 13 alphanumeric password for the mysql root user. 
function mysql_root_password() {
	unset PASS
	PASS=`cat /dev/urandom| tr -dc 'a-zA-Z0-9' | head -c 13`
	mysqladmin -u root password $PASS
	echo "" > /root/.my.cnf
	echo "[client]" >> /root/.my.cnf
	echo "user="root"" >> /root/.my.cnf
	echo "password='$PASS'" >> /root/.my.cnf
	unset PASS
}


# cpanel_perl_module_fix
# Grabs and installs some perl modules, that cpanel has trouble installing (and it breaks the cpanel install)
# Needed so EA will run
function cpanel_perl_module_fix() {
	MODULES="Pod-Escapes-1.04 Pod-Simple-3.06  Test-Pod-1.26 YAML-Syck-1.04 BSD-Resource-1.2901 Curses-UI-0.9603 File-Copy-Recursive-0.36"
	for m in $MODULES; do
		cd /home/temp
		wget http://layer3.liquidweb.com/rpm/perl/${m}.tar.gz
		tar xzf ${m}.tar.gz
		cd ${m}
		perl Makefile.PL && make && make install
	done
}

# cpanel_configure_apache
# Configures Apache for Cpanel installs
#   Inspects $INITADMIN - make sure get_server_data is called before this.
function cpanel_configure_apache() {
   if [ "$INITADMIN" ]; then

	#if [ "$SHARED_SERVER" ]; then
	#	rm -f /var/cpanel/easy/apache/prefs.yaml
	#	mv /home/temp/prefs.yaml /var/cpanel/easy/apache/prefs.yaml
	#	mv /home/temp/shared_server.yaml /var/cpanel/easy/apache/profile/custom/shared_server.yaml
	#fi

cat > /var/cpanel/easy/apache/profile/custom/lw_server_secure.yaml << EOF
# make sure any changes here are reflected in Cpanel::Easy::Apache::get_apache_defaults_text() if necessary
--- 
Apache: 
  optmods: 
    Access: 0
    Actions: 0
    Alias: 0
    Asis: 0
    AuthAnon: 0
    AuthDB: 0
    AuthDBM: 0
    AuthDigest: 0
    AuthLDAP: 0
    AuthnAlias: 0
    AuthnAnon: 0
    AuthnDBD: 0
    AuthnDBM: 0
    AuthnDefault: 0
    AuthnzLDAP: 0
    AuthzDBM: 0
    AuthzHost: 0
    AuthzOwner: 0
    Autoindex: 0
    Bucketeer: 0
    Cache: 0
    CaseFilter: 0
    CaseFilterIn: 0
    CernMeta: 0
    CharsetLite: 0
    DAVFs: 0
    DAVLock: 0
    DBD: 0
    DIR: 0
    Dav: 0
    Deflate: 1
    DiskCache: 0
    Distcache: 0
    Dumpio: 0
    Echo: 0
    Env: 0
    Expires: 1
    ExtFilter: 0
    Fastcgi: 0
    FileCache: 0
    Fileprotect: 1
    Frontpage: 1
    Headers: 1
    Ident: 0
    Imagemap: 0
    LDAP: 0
    LogAgent: 0
    LogConfig: 0
    LogForensic: 0
    LogReferer: 0
    MPMEvent: 0
    MPMLeader: 0
    MPMPerchild: 0
    MPMPrefork: 0
    MPMThreadpool: 0
    MPMWorker: 0
    MemCache: 0
    Mime: 0
    MimeMagic: 0
    MmapStatic: 0
    Negotiation: 0
    OptionalFnExport: 0
    OptionalFnImport: 0
    OptionalHookExport: 0
    OptionalHookImport: 0
    PHPAsUser: 1
    Proxy: 1
    RaiseFDSetsize: 0
    RaiseHardServerLimit: 0
    Rewrite: 1
    Setenvif: 0
    Speling: 0
    Status: 0
    UniqueId: 1
    Userdir: 0
    Usertrack: 0
    Version: 0
    VhostAlias: 0
  version: 2_2
Cpanel::Easy::Zendopt: 1
Cpanel::Easy::IonCubeLoader: 1
Cpanel::Easy::ModGzip: 0
Cpanel::Easy::ModPerl: 0
Cpanel::Easy::ModSec: 1
Cpanel::Easy::PHP4: 0
Cpanel::Easy::PHP4::4_4: 0
Cpanel::Easy::PHP4::4_5: 0
Cpanel::Easy::PHP4::4_6: 0
Cpanel::Easy::PHP4::4_7: 0
Cpanel::Easy::PHP4::4_8: 0
Cpanel::Easy::PHP4::4_9: 1
Cpanel::Easy::PHP4::Bcmath: 1
Cpanel::Easy::PHP4::Bz2: 0
Cpanel::Easy::PHP4::CGI: 0
Cpanel::Easy::PHP4::Calendar: 1
Cpanel::Easy::PHP4::Curl: 0
Cpanel::Easy::PHP4::CurlSSL: 0
Cpanel::Easy::PHP4::DBX: 0
Cpanel::Easy::PHP4::Dbase: 0
Cpanel::Easy::PHP4::DiscardPath: 0
Cpanel::Easy::PHP4::DomXslt: 0
Cpanel::Easy::PHP4::Exif: 0
Cpanel::Easy::PHP4::FTP: 1
Cpanel::Easy::PHP4::Fastcgi: 0
Cpanel::Easy::PHP4::ForceCGIRedirect: 1
Cpanel::Easy::PHP4::GD: 0
Cpanel::Easy::PHP4::Gettext: 0
Cpanel::Easy::PHP4::Iconv: 1
Cpanel::Easy::PHP4::Imap: 1
Cpanel::Easy::PHP4::Java: 0
Cpanel::Easy::PHP4::MM: 0
Cpanel::Easy::PHP4::MagicQuotes: 1
Cpanel::Easy::PHP4::MailHeaders: 0
Cpanel::Easy::PHP4::Mbregex: 0
Cpanel::Easy::PHP4::Mbstring: 0
Cpanel::Easy::PHP4::Mcrypt: 0
Cpanel::Easy::PHP4::MemoryLimit: 0
Cpanel::Easy::PHP4::Mhash: 0
Cpanel::Easy::PHP4::MimeMagic: 0
Cpanel::Easy::PHP4::Ming: 0
Cpanel::Easy::PHP4::MysqlOfSystem: 1
Cpanel::Easy::PHP4::Openssl: 0
Cpanel::Easy::PHP4::PDFLib: 0
Cpanel::Easy::PHP4::POSIX: 0
Cpanel::Easy::PHP4::PathInfoCheck: 0
Cpanel::Easy::PHP4::PcreRegex: 0
Cpanel::Easy::PHP4::Pear: 0
Cpanel::Easy::PHP4::Pgsql: 0
Cpanel::Easy::PHP4::Pspell: 0
Cpanel::Easy::PHP4::SNMP: 0
Cpanel::Easy::PHP4::SafeMode: 0
Cpanel::Easy::PHP4::SafePHPCGI: 0
Cpanel::Easy::PHP4::Sockets: 1
Cpanel::Easy::PHP4::Swf: 0
Cpanel::Easy::PHP4::TTF: 0
Cpanel::Easy::PHP4::Versioning: 0
Cpanel::Easy::PHP4::Wddx: 0
Cpanel::Easy::PHP4::XmlRPC: 0
Cpanel::Easy::PHP4::XsltSablot: 0
Cpanel::Easy::PHP4::ZendMultibyte: 0
Cpanel::Easy::PHP4::Zip: 0
Cpanel::Easy::PHP4::Zlib: 1
Cpanel::Easy::PHP5: 1
Cpanel::Easy::PHP5::2_2: 0
Cpanel::Easy::PHP5::2_3: 0
Cpanel::Easy::PHP5::2_4: 0
Cpanel::Easy::PHP5::2_5: 0
Cpanel::Easy::PHP5::2_6: 0
Cpanel::Easy::PHP5::2_8: 0
Cpanel::Easy::PHP5::2_9: 0
Cpanel::Easy::PHP5::2_10: 0
Cpanel::Easy::PHP5::2_11: 0
Cpanel::Easy::PHP5::2_12: 0
Cpanel::Easy::PHP5::2_13: 0
Cpanel::Easy::PHP5::2_17: 1
Cpanel::Easy::PHP5::Bcmath: 1
Cpanel::Easy::PHP5::Bz2: 0
Cpanel::Easy::PHP5::CGI: 0
Cpanel::Easy::PHP5::Calendar: 1
Cpanel::Easy::PHP5::Curl: 1
Cpanel::Easy::PHP5::CurlSSL: 1
Cpanel::Easy::PHP5::Curlwrappers: 0
Cpanel::Easy::PHP5::DBX: 0
Cpanel::Easy::PHP5::Dbase: 0
Cpanel::Easy::PHP5::DiscardPath: 0
Cpanel::Easy::PHP5::DomXslt: 0
Cpanel::Easy::PHP5::Exif: 1
Cpanel::Easy::PHP5::FTP: 1
Cpanel::Easy::PHP5::Fastcgi: 0
Cpanel::Easy::PHP5::ForceCGIRedirect: 1
Cpanel::Easy::PHP5::GD: 1
Cpanel::Easy::PHP5::Gettext: 1
Cpanel::Easy::PHP5::Iconv: 1
Cpanel::Easy::PHP5::Imap: 1
Cpanel::Easy::PHP5::Java: 0
Cpanel::Easy::PHP5::MM: 0
Cpanel::Easy::PHP5::MagicQuotes: 1
Cpanel::Easy::PHP5::MailHeaders: 0
Cpanel::Easy::PHP5::Mbregex: 1
Cpanel::Easy::PHP5::Mbstring: 1
Cpanel::Easy::PHP5::Mcrypt: 1
Cpanel::Easy::PHP5::MemoryLimit: 0
Cpanel::Easy::PHP5::Mhash: 1
Cpanel::Easy::PHP5::MimeMagic: 0
Cpanel::Easy::PHP5::Ming: 0
Cpanel::Easy::PHP5::Mysql: 1
Cpanel::Easy::PHP5::MysqlOfSystem: 1
Cpanel::Easy::PHP5::Mysqli: 1
Cpanel::Easy::PHP5::Openssl: 1
Cpanel::Easy::PHP5::PDFLib: 0
Cpanel::Easy::PHP5::PDO: 1
Cpanel::Easy::PHP5::PDOMySQL: 1
Cpanel::Easy::PHP5::POSIX: 0
Cpanel::Easy::PHP5::PathInfoCheck: 0
Cpanel::Easy::PHP5::Pear: 0
Cpanel::Easy::PHP5::Pgsql: 0
Cpanel::Easy::PHP5::Pspell: 0
Cpanel::Easy::PHP5::SNMP: 0
Cpanel::Easy::PHP5::SOAP: 0
Cpanel::Easy::PHP5::SafeMode: 0
Cpanel::Easy::PHP5::SafePHPCGI: 0
Cpanel::Easy::PHP5::Sockets: 1
Cpanel::Easy::PHP5::Swf: 0
Cpanel::Easy::PHP5::TTF: 1
Cpanel::Easy::PHP5::Tidy: 0
Cpanel::Easy::PHP5::Versioning: 0
Cpanel::Easy::PHP5::Wddx: 0
Cpanel::Easy::PHP5::WithoutIconv: 0
Cpanel::Easy::PHP5::XmlRPC: 0
Cpanel::Easy::PHP5::XsltSablot: 0
Cpanel::Easy::PHP5::ZendMultibyte: 0
Cpanel::Easy::PHP5::Zip: 1
Cpanel::Easy::PHP5::Zlib: 1
Cpanel::Easy::PHPSuHosin: 1
_meta: 
  name: Liquid Web Server Secure
  note: This is the default configuration with common modules selected and the addition of Mod suPHP for added security measures and tracking for PHP scripts. See http://www.suphp.org for more information about suPHP.
  revision: 20120502
EOF

	/scripts/easyapache --profile=lw_server_secure --build

    # Enable mod_security rules
    wget http://updates.atomicorp.com/channels/rules/delayed/modsec-.tar.gz
    tar -xzvf modsec-.tar.gz -C /usr/local/apache/conf/

    cat > /usr/local/apache/conf/modsec2.user.conf << EOF
SecRequestBodyAccess On
SecDataDir /var/tmp
SecTmpDir /var/tmp
SecPcreMatchLimit 150000
SecPcreMatchLimitRecursion 150000
Include "/usr/local/apache/conf/modsec/00_asl_whitelist.conf"
Include "/usr/local/apache/conf/modsec/05_asl_exclude.conf"
Include "/usr/local/apache/conf/modsec/10_asl_antimalware.conf"
Include "/usr/local/apache/conf/modsec/10_asl_rules.conf"
Include "/usr/local/apache/conf/modsec/11_asl_data_loss.conf"
Include "/usr/local/apache/conf/modsec/20_asl_useragents.conf"
Include "/usr/local/apache/conf/modsec/30_asl_antispam.conf"
Include "/usr/local/apache/conf/modsec/30_asl_antispam_referrer.conf"
Include "/usr/local/apache/conf/modsec/40_asl_apache2-rules.conf"
Include "/usr/local/apache/conf/modsec/50_asl_rootkits.conf"
Include "/usr/local/apache/conf/modsec/60_asl_recons.conf"
Include "/usr/local/apache/conf/modsec/99_asl_exclude.conf"
Include "/usr/local/apache/conf/modsec/99_asl_jitp.conf"
Include "/usr/local/apache/conf/modsec/99_asl_redactor.conf"
EOF

    mkdir /etc/asl
    touch /etc/asl/whitelist

    perl -i -p -e 's/SecRule.*\(exec\\s\*\\\(\\s\*@\)\" \\//g' /usr/local/apache/conf/modsec/10_asl_rules.conf
    perl -i -p -e 's/.*id:380022.*//g' /usr/local/apache/conf/modsec/10_asl_rules.conf

    # Enable suPHP for ServerSecure installs
    /usr/local/cpanel/bin/rebuild_phpconf 5 none suphp enabled
else
    #wget -P /var/cpanel/easy/apache/profile/custom http://layer3.liquidweb.com/configs/apache/lw_default.yaml
	#do not need to run EA - Default install is part of the tar file
    #/scripts/easyapache --profile=lw_default --build
    #/usr/local/cpanel/bin/rebuild_phpconf 5 none dso enabled
fi
}

# install_firewall
# Installs iptables (core manged only right now)
function install_firewall() {
	wget -P /home/temp http://layer3.liquidweb.com/configs/firewall/core.iptables && mv /home/temp/core.iptables /etc/sysconfig/iptables
	/etc/rc.d/init.d/iptables restart
}

# fix_lftp
# disables ssl for FTP connections in lftp, leaving it on causes connection issues
function fix_lftp() {
echo -e "\n#Disable SSL\nset ftp:ssl-allow no" >> /etc/lftp.conf
}

# disable console blanking
# Stops the screen saver from blanking the screen
function disable_screensaver() {
	echo "setterm -powersave off -blank 0" >> /etc/rc.local
}

# disable CPU speed throttling
# Turns off cpuspeed, which is buggy and can't ramp the speed back up
function disable_cputhrottle() {
    chkconfig cpuspeed off
}

#secure_ftp
#Secures FTP by disabling root ftp logins
function secure_ftp() {
	sed -i -e '/RootPassLogins:/s/yes/no/g' /var/cpanel/conf/pureftpd/main
	/usr/local/cpanel/whostmgr/bin/whostmgr2 doftpconfiguration

}

# install_csf
#installs CSF firewall
function install_csf() {
	cd /root
	rm -f csf.tgz
	wget http://www.configserver.com/free/csf.tgz
	tar -xzf csf.tgz
	cd csf
	sh remove_apf_bfd.sh
	sh install.sh
	sed -i -e 's/TESTING = "1"/TESTING = "0"/g' /etc/csf/csf.conf
	#Enable SMTP tweak in CSF
	sed -i -e 's/SMTP_BLOCK = "0"/SMTP_BLOCK = "1"/g' /etc/csf/csf.conf
cat << EOF > /etc/csf/csf.allow
# Monitoring servers (MySQL ports only)
tcp:in:d=3306:s=10.20.9.0/24
tcp:in:d=3306:s=10.30.9.0/24
tcp:in:d=3306:s=209.59.139.14
tcp:in:d=3306:s=67.227.128.125
tcp:in:d=3306:s=67.227.128.126
tcp:in:d=3306:s=69.16.234.107
tcp:in:d=3306:s=69.16.234.108
tcp:in:d=3306:s=69.16.234.118
tcp:in:d=3306:s=69.16.234.119
tcp:in:d=3306:s=69.16.234.122
tcp:in:d=3306:s=69.16.234.123
tcp:in:d=3306:s=69.16.234.124
tcp:in:d=3306:s=69.16.234.125
tcp:in:d=3306:s=69.16.234.126

10.30.9.0/24
10.20.9.0/24
10.40.11.0/28
209.59.139.14
69.16.234.126
69.16.234.125
69.16.234.124
69.16.234.123
69.16.234.122
69.16.234.119
69.16.234.118
69.16.234.107 
69.16.234.108 
67.227.128.126
67.227.128.125

10.10.10.10
10.254.254.254
EOF

	/etc/init.d/csf restart
	cd /root/
	rm -rf /root/csf*
}

#noexec_dev_shm
#adds the noexec option to /dev/shm mount
function noexec_dev_shm() {
	sed -i 's/tmpfs\s\{3,\}defaults/tmpfs   defaults,nosuid,noexec/g' /etc/fstab
}

