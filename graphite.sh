#!/bin/bash

# This installation is for the following software versions:

    # OS: CentOS Server 6.5 (Final)
    # Server Version: Apache/2.2.15 (Unix)
    # Python: Python 2.6.6
    # Graphite: Graphite 0.9.12


# Download all necessary packages for graphite
function fetchPackages() {

    printf "\n#################################\n"
    printf "# Installing necessary packages # \n"
    printf "#################################\n\n"

    # Install EPEL (Extra Packages for Enterprise Linux)
    rpm -Uvh 'http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm'
    echo

    # Make sure we're all up to date
    yum update && yum upgrade

    # Install packages specifically for graphite
    yum -y install python-whisper python-carbon graphite-web python-memcached python-ldap memcached httpd

    printf "\nPackages successfully installed!\n"
}

# When called, pause the shell script until further notice
function pause() {
    read -p "$*"
}

# Runs after graphite is installed.
# Executes installation of StatsD if selected.
function menu() {
    while true; do

        echo
        read -p "Would you like to install StatsD while you're at it? (y/n): " answer

        # Accept upper and lowercase strings
        if [ $(echo "$answer" | tr [:upper:] [:lower:]) = "n" ] ; then
            printf "\nGoodbye.\n\n"
            exit

        # Install StatsD
        elif [ $(echo "$answer" | tr [:upper:] [:lower:]) = "y" ] ; then

            printf "\nInstalling Git..\n"
            yum -y install git

            printf "\nInstalling NodeJS\n"
            yum -y groupinstall 'Development Tools'
            git clone 'https://github.com/joyent/node.git'
            pushd node

            printf "* Warning: Building NodeJS takes approximately 20 minutes.\n\n"
            pause 'Press [Enter] key to continue...'

            # Build
            ./configure && make && make install
            popd
            rm -rf node

            # Install npm
            printf "\nInstalling Node Package Manager (npm)\n"
            yum -y install npm --enablerepo=epel

            # Install Express
            npm install express

            # Install and configure StatsD
            printf "\n=========================\n"
            printf "= Now installing StatsD =\n"
            printf "=========================\n"

            git clone 'https://github.com/etsy/statsd.git'
            mv statsd '/usr/lib/python2.6/site-packages/' && cd '/usr/lib/python2.6/site-packages/statsd'
            cp 'exampleConfig.js' 'local.js'

            printf "\nInside local.js, scroll to the very bottom and set 'graphiteHost: ' to 'yourservername\n"
            printf "\nRemember, once in the editor, you can scroll up at anytime to view the database configuration.\n\n"

            # Pause shell script
            pause 'Press [Enter] key to continue...'
            printf "\n======================================================================================\n"

            vim '/usr/lib/python2.6/site-packages/statsd/local.js'

            # Assign ownership to apache
            chown -R apache:apache '/usr/lib/python2.6/site-packages/statsd/'
            printf "\nPermissions assigned!\n"

            # Restart services for graphite to work
            printf "\nCarbon-cache is restarting...\n"
            service carbon-cache restart

            printf "\nMemcached is restarting...\n"
            service memcached restart

            printf "\nApache is restarting...\n"
            service httpd restart

            #Start StatsD
            node 'stats.js' 'local.js'

            # Important, otherwise we'll keep looping
            printf "Installation complete!\n\n"
            exit

        else
            printf "Invalid input. Please try again.\n\n"
        fi

    done
}

# Graphite setup and configuration.
function setup() {

    printf "\nFollow the prompts to create a superuser.\n"
    printf "You will use this account to log into graphite.\n\n"

    # Create superuser
    python '/usr/lib/python2.6/site-packages/graphite/manage.py' syncdb

    # Open vim to edit local_settings.py
    cat 'local_settings_readme.txt'
    printf "\nRemember, once in the editor, you can scroll up at anytime to view the database configuration.\n\n"

    # Pause shell script
    pause 'Press [Enter] key to continue...'
    printf "\n======================================================================================\n"

    vim '/usr/lib/python2.6/site-packages/graphite/local_settings.py'

    printf "\n++++++++++++++++++++++++++++++++++++++++++++++++++++\n"
    printf "+ Assigning permissions for /var/lib/graphite-web/ +\n"
    printf "++++++++++++++++++++++++++++++++++++++++++++++++++++\n"

    # Assigning permissions
    chown -R apache:apache '/var/lib/graphite-web/'
    printf "\nPermissions assigned!\n"

    printf "\n***************************************************************\n"
    printf "* Assigning permissions for /usr/lib/python2.6/site-packages/ *\n"
    printf "***************************************************************\n"

    # Assigning permissions
    chown -R apache:apache '/usr/lib/python2.6/site-packages/'
    printf "\nPermissions assigned!\n"

    # Restart services for graphite to work
    printf "\nCarbon-cache is restarting...\n"
    service carbon-cache restart

    printf "\nMemcached is restarting...\n"
    service memcached restart

    printf "\nApache is restarting...\n"
    service httpd restart

    printf "\nInstallation complete!\n"
    printf "Point your browser to http://yourservername\n\n"

    menu
}

# Initialize all functions
function init() {

    # Execute the following functions
    fetchPackages
    setup
}

# Run init()
init
