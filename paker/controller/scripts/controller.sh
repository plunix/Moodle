#!/bin/bash

# O365 plugins are released only for 'MOODLE_xy_STABLE',
# whereas we want to support the Moodle tagged versions (e.g., 'v3.4.2').
# This function helps getting the stable version # (for O365 plugin ver.)
# from a Moodle version tag. This utility function recognizes tag names
# of the form 'vx.y.z' only.
function get_o365plugin_version_from_moodle_version {
  local moodleVersion=${1}
  if [[ "$moodleVersion" =~ v([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
    echo "MOODLE_${BASH_REMATCH[1]}${BASH_REMATCH[2]}_STABLE"
  else
    echo $moodleVersion
  fi
}

# For Moodle tags (e.g., "v3.4.2"), the unzipped Moodle dir is no longer
# "moodle-$moodleVersion", because for tags, it's without "v". That is,
# it's "moodle-3.4.2". Therefore, we need a separate helper function for that...
function get_moodle_unzip_dir_from_moodle_version {
  local moodleVersion=${1}
  if [[ "$moodleVersion" =~ v([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
    echo "moodle-${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}"
  else
    echo "moodle-$moodleVersion"
  fi
}

function get_php_version {
    if [ -z "$_PHPVER" ]; then
        _PHPVER=`/usr/bin/php -r "echo PHP_VERSION;" | /usr/bin/cut -c 1,2,3`
    fi
    echo $_PHPVER
}

function main {
    
    # common packages the script needs

    export DEBIAN_FRONTEND=noninteractive
    apt update
    sleep 10  
    apt install -y zip unzip curl procps software-properties-common ca-certificates apt-transport-https lsb-release gnupg
    
    add-apt-repository ppa:ubuntu-toolchain-r/ppa -y
    add-apt-repository ppa:ondrej/php -y
    add-apt-repository ppa:gluster/glusterfs-3.10 -y 

    curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
    AZ_REPO=$(lsb_release -cs)
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" |  tee /etc/apt/sources.list.d/azure-cli.list
    
    apt -qq -o=Dpkg::Use-Pty=0 update
    apt install -y unattended-upgrades fail2ban rsyslog git glusterfs-client cifs-utils mysql-client azure-cli
    curl https://stedolan.github.io/jq/download/linux64/jq > /usr/bin/jq && chmod +x /usr/bin/jq

    # php, nginx, Moodle requirements
    apt install -y nginx php$phpVersion-fpm varnish php$phpVersion php$phpVersion-cli \
    php$phpVersion-curl php$phpVersion-zip \
    graphviz aspell php$phpVersion-common php$phpVersion-soap php$phpVersion-json php$phpVersion-redis \
    php$phpVersion-bcmath php$phpVersion-gd  php$phpVersion-xmlrpc php$phpVersion-intl php$phpVersion-xml php$phpVersion-bz2 \
    php-pear php$phpVersion-mbstring php$phpVersion-dev php$phpVersion-mysql mcrypt

    PhpVer=$(get_php_version)
    
    # moodle and plugins 
    o365pluginVersion=$(get_o365plugin_version_from_moodle_version $moodleVersion)
    moodleStableVersion=$o365pluginVersion  # Need Moodle stable version for GDPR plugins, and o365pluginVersion is just Moodle stable version, so reuse it.
    moodleUnzipDir=$(get_moodle_unzip_dir_from_moodle_version $moodleVersion)
    mkdir /etc/moodleinstall
    echo "$moodleVersion"
    sleep 1
    curl -k --max-redirs 10 https://github.com/moodle/moodle/archive/"$moodleVersion".zip -L -o /etc/moodleinstall/moodle.zip
    curl -k --max-redirs 10 https://github.com/moodlehq/moodle-tool_policy/archive/"$moodleStableVersion".zip -L -o /etc/moodleinstall/plugin-policy.zip
    curl -k --max-redirs 10 https://github.com/moodlehq/moodle-tool_dataprivacy/archive/"$moodleStableVersion".zip -L -o /etc/moodleinstall/plugin-dataprivacy.zip
    curl -k --max-redirs 10 https://github.com/Microsoft/o365-moodle/archive/"$o365pluginVersion".zip -L -o /etc/moodleinstall/o365.zip
    curl -k --max-redirs 10 https://github.com/catalyst/moodle-search_elastic/archive/master.zip -L -o /etc/moodleinstall/plugin-elastic.zip
    curl -k --max-redirs 10 https://github.com/catalyst/moodle-local_aws/archive/master.zip -L -o /etc/moodleinstalllocal-aws.zip
    curl -k --max-redirs 10 https://github.com/catalyst/moodle-search_azure/archive/master.zip -L -o /etc/moodleinstall/plugin-azure-search.zip
    curl -k --max-redirs 10 https://github.com/catalyst/moodle-tool_objectfs/archive/master.zip -L -o /etc/moodleinstall/plugin-objectfs.zip
    curl -k --max-redirs 10 https://github.com/catalyst/moodle-local_azure_storage/archive/master.zip -L -o /etc/moodleinstall/plugin-azurelibrary.zip
    wget -q -O azcopy_v10.tar.gz https://aka.ms/downloadazcopy-v10-linux && tar -xf azcopy_v10.tar.gz --strip-components=1 && mv ./azcopy /usr/bin/
}

set -ex
echo "Script starting @ `date` "
main
echo "Script ended @ `date` "
set +ex