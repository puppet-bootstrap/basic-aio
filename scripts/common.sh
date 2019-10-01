#!/bin/bash

puppet_release="$1"
el_release="$2"
ip_subnet="$3"

if [ -f /etc/sysconfig/network-scripts/ifcfg-eth1 ] ; then
    sed -i \
        -e '/^NM_CONTROLLED=/d;$aNM_CONTROLLED=yes' \
        -e '/^BOOTPROTO=/d;$aBOOTPROTO=static' \
        /etc/sysconfig/network-scripts/ifcfg-eth1
    /sbin/ifdown eth1
    /sbin/ifup eth1
fi

release_url="http://yum.puppet.com/puppet${puppet_release}-release-el-${el_release}.noarch.rpm"

yum -y install $release_url --nogpgcheck

yum -y install puppet-agent

# Source the profile to get the path
. /etc/profile.d/puppet-agent.sh

# We don't have working DNS, so fake it with hosts entries.
declare -A hosts
hosts=(
    [puppet.vagrant]="${ip_subnet}.5"
    [agent.vagrant]="${ip_subnet}.6"
)
for host in "${!hosts[@]}" ; do
    puppet resource host "$host" ip="${hosts[$host]}" host_aliases="${host%%.*}"
done
