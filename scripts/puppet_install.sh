#!/bin/bash

set -e

release_url=http://yum.puppetlabs.com/puppet5/puppet5-release-el-7.noarch.rpm

yum -y install $release_url --nogpgcheck

yum -y install puppetserver puppet-agent

echo "192.168.32.5  puppet.vagrant  puppet" >> /etc/hosts

# Bootstrap the puppet module configuration
# Source the profile to get the path
. /etc/profile.d/puppet-agent.sh
puppet module install puppet/r10k
puppet module install puppet/hiera --ignore-dependencies
puppet apply /vagrant/bootstrap.pp

# Deploy the control repo with the newly installed r10k
r10k deploy environment -pv

# Enable autosigning nodes in the .vagrant domain
echo '*.vagrant' > /etc/puppetlabs/puppet/autosign.conf
echo 'vagrant.mcollective' >> /etc/puppetlabs/puppet/autosign.conf

# Start the puppet master so further changes are under puppet control
/bin/systemctl enable puppetserver
/bin/systemctl start puppetserver


sleep 30

# If puppet successfully applied changes, it returns 2.
# Vagrant sees a non-zero return code as a failure. If puppet returns 2,
# return a zero so vagrant doesn't report an error
puppet agent -t || [ $? -eq 2 ] && /bin/true

su -- vagrant -c 'mco choria request_cert'
