#!/bin/bash

function get_php_version {
    if [ -z "$_PHPVER" ]; then
        _PHPVER=`/usr/bin/php -r "echo PHP_VERSION;" | /usr/bin/cut -c 1,2,3`
    fi
    echo $_PHPVER
}

function main {
  export DEBIAN_FRONTEND=noninteractive
  apt update
  apt install -y zip unzip curl procps software-properties-common ca-certificates apt-transport-https lsb-release gnupg
  
  # add repositories

  curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
  AZ_REPO=$(lsb_release -cs)
  echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" |  tee /etc/apt/sources.list.d/azure-cli.list
  
  
  add-apt-repository ppa:ondrej/php -y > /dev/null 2>&1
  add-apt-repository ppa:ubuntu-toolchain-r/ppa
  add-apt-repository ppa:gluster/glusterfs-3.10 -y
  apt-get -qq -o=Dpkg::Use-Pty=0 update 

  # install packages
  export DEBIAN_FRONTEND=noninteractive
  apt-get --yes \
    --no-install-recommends \
    -qq -o=Dpkg::Use-Pty=0 \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
    install \
    azure-cli \
    software-properties-common \
    rsyslog \
    git \
    unattended-upgrades \
    tuned \
    varnish \
    php$phpVersion \
    php$phpVersion-cli \
    php$phpVersion-curl \
    php$phpVersion-zip \
    php-pear \
    php$phpVersion-mbstring \
    mcrypt \
    php$phpVersion-dev \
    graphviz \
    aspell \
    php$phpVersion-soap \
    php$phpVersion-json \
    php$phpVersion-redis \
    php$phpVersion-bcmath \
    php$phpVersion-gd \
    php$phpVersion-pgsql \
    php$phpVersion-mysql \
    php$phpVersion-xmlrpc \
    php$phpVersion-intl \
    php$phpVersion-xml \
    php$phpVersion-bz2 \
    unattended-upgrades \
    php$phpVersion-fpm \
    fail2ban \
    cifs-utils \
    nginx \
    glusterfs-client \
    g++ \
    build-essential \
    mdadm

  curl https://stedolan.github.io/jq/download/linux64/jq > /usr/bin/jq && chmod +x /usr/bin/jq
  
  # install azcopy
  wget -q -O azcopy_v10.tar.gz https://aka.ms/downloadazcopy-v10-linux && tar -xf azcopy_v10.tar.gz --strip-components=1 && mv ./azcopy /usr/bin/

  # kernel settings
  cat << EOF > /etc/sysctl.d/99-network-performance.conf
    net.core.somaxconn = 65536
    net.core.netdev_max_backlog = 5000
    net.core.rmem_max = 16777216
    net.core.wmem_max = 16777216
    net.ipv4.tcp_wmem = 4096 12582912 16777216
    net.ipv4.tcp_rmem = 4096 12582912 16777216
    net.ipv4.route.flush = 1
    net.ipv4.tcp_max_syn_backlog = 8096
    net.ipv4.tcp_tw_reuse = 1
    net.ipv4.ip_local_port_range = 10240 65535
EOF
  # apply the new kernel settings
  sysctl -p /etc/sysctl.d/99-network-performance.conf

  # scheduling IRQ interrupts on the last two cores of the cpu
  # masking 0011 or 00000011 the result will always be 3 echo "obase=16;ibase=2;0011" | bc | tr '[:upper:]' '[:lower:]'
  if [ -f /etc/default/irqbalance ]; then
    sed -i "s/\#IRQBALANCE_BANNED_CPUS\=/IRQBALANCE_BANNED_CPUS\=3/g" /etc/default/irqbalance
    systemctl restart irqbalance.service 
  fi

  # configuring tuned for throughput-performance
  systemctl enable tuned
  tuned-adm profile throughput-performance
}

set -ex
echo "Script starting @ `date` "
main
echo "Script ended @ `date` "
set +ex