#!/bin/bash

rpm -ihv http://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm

yum -y install puppetserver puppet-agent

echo "192.168.32.5  puppet.vagrant  puppet" >> /etc/hosts

# Bootstrap the puppet module configuration
# Source the profile to get the path
. /etc/profile.d/puppet-agent.sh
puppet module install puppet/r10k
puppet apply /vagrant/bootstrap.pp
r10k deploy environment -pv

# Start the puppet master so further changes are under puppet control
/bin/systemctl start puppetserver
