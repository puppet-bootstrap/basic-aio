#!/bin/bash

if [ -f /etc/sysconfig/network-scripts/ifcfg-eth1 ] ; then
    sed -i \
        -e '/^NM_CONTROLLED=/d;$aNM_CONTROLLED=yes' \
        -e '/^BOOTPROTO=/d;$aBOOTPROTO=static' \
        /etc/sysconfig/network-scripts/ifcfg-eth1
    /sbin/ifdown eth1
    /sbin/ifup eth1
fi

release_url=http://yum.puppetlabs.com/puppet5/puppet5-release-el-7.noarch.rpm

yum -y install $release_url --nogpgcheck

yum -y install puppet-agent

# Source the profile to get the path
. /etc/profile.d/puppet-agent.sh

puppet apply -e 'host { $facts["fqdn"]: ip => $facts["networking"]["interfaces"]["eth1"]["ip"], host_aliases => $facts["hostname"] }'
