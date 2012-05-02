#!/bin/bash
#
# post install script 
# 
# This script should be run online, with a public IP and CPanel license assigned to the server. 

if [ -f /root/.bashrc ]; then
	source /root/.bashrc
fi

if [ -f /root/cpanel-functions.sh ]; then
   source "/root/cpanel-functions.sh"
   getrelease
else
   echo "cpanel-function.sh is missing, cannot run."
   exit 1;
fi

if [ ! -d /home/temp ]; then
	mkdir /home/temp
fi

chattr +i /usr/bin/screen

# Get basic server info and set the root password
get_server_data
set_root_passwd

alter_bash

# Install Ruby - why?
/scripts/installruby

install_lpskel

install_ntp

set_syncookies

update_cpanel_settings

move_domlogs

if [ "$FANTASTICO" ]; then
	install_fantastico
fi

if [ "$SOFTAC" ]; then
	install_softaculous
fi	

touch /root/.my.cnf

fix_logrotate

install_glibc_devel
install_headers

# Enable backups
if [ "$BACKUPS" ]; then
	configure_cpanel_backups 
fi

fix_cpanel_license

do_raid

fix_bind 

if [ "$INITADMIN" ]; then
        echo "Running ServerSecure Setup..."

        #
        # Install firewall and security scripts - ServerSecure starts here
        #
        fix_ssh

        /usr/bin/yum -y install netpbm netpbm-devel netpbm-progs iptraf
	# Removing the ddos package from this list, as per siena. --dwalters 20091125
        /usr/bin/yum -c /usr/local/lp/configs/yum/yum.conf -y install lp-security-scripts iftop iptraf
	
        /scripts/perlinstaller Digest::SHA1
        /usr/bin/yum -c /usr/local/lp/configs/yum/yum.conf -y install lp-rkhunter lp-chkrootkit


        install_mytop

        # Install clamAV and RBLs
        #
        activate_cpanel_pro
        configure_clam

        configure_exim
	
	fix_courier

	fix_clam
	
	secure_ftp

	noexec_dev_shm

        # Turn off compilers
        #/scripts/compilers off

        # SMTP Tweak
        #/scripts/smtpmailgidonly on

        # Turn off shell access
        #adduser -D -s /usr/local/cpanel/bin/noshell

        # Enable fork bomb protection
        #echo "Enabling shell fork bomb protection..."
        #curl "http://root:${ROOTPW}@localhost:2086/scripts2/modlimits?limits=1" > /dev/null

        #echo "Disabling dangerous commands..."
        #disable_binaries > /dev/null

        /scripts/securetmp --auto
        ##
        ## ServerSecure stuff ends here
        ##

if [ "$SECPLUS" ]; then

install_secplus

else

install_csf

fi

fi

whm_lic_agree

fix_ftp

fix_cpanel_ssl

/scripts/rebuildippool

update_mysql

# Install missing perl modules so EA will run, Cpanel is retarded
cpanel_perl_module_fix

# Install Apache -- If server secure is set, use that
cpanel_configure_apache

# Install Mr. Radar
install_mrradar "cpanel"

echo "Cleaning up temp files (/home/temp)..."
rm -rf /home/temp && mkdir /home/temp

echo "Restarting CPanel..."
/etc/init.d/cpanel restart

echo "Updating Cpanel..."
/scripts/upcp --force

echo "System setup done. Remember to reboot the server"

if [ "$SECPLUS" ]; then
echo "WARNING WARNING WARNING the new SSH port is now 22222 please make a sure to set the su user and the alternat port in billing!!."
fi

chattr -i /usr/bin/screen

mysql_root_password

# Disable screensaver
disable_screensaver

# Disable CPU Throttling
disable_cputhrottle

# lftp
fix_lftp

# Euthanize self
cd /root
rm -fv $0
rm -fv "functions.sh"

exit 0
