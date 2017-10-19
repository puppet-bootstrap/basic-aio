#!/bin/bash


#rpm -ihv https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

yum -y install vim

if [ -f /etc/sysconfig/network-scripts/ifcfg-eth1 ] ; then
    sed -i \
        -e '/^NM_CONTROLLED=/d;$aNM_CONTROLLED=yes' \
        -e '/^BOOTPROTO=/d;$aBOOTPROTO=static' \
        /etc/sysconfig/network-scripts/ifcfg-eth1
    /sbin/ifdown eth1
    /sbin/ifup eth1
fi
