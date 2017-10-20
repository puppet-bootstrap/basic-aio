#!/bin/bash

set -e

yum -y install puppetserver

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
puppet resource service puppetserver ensure=running enable=true

sleep 30

# If puppet successfully applied changes, it returns 2.
# Vagrant sees a non-zero return code as a failure. If puppet returns 2,
# return a zero so vagrant doesn't report an error
puppet agent -t || [ $? -eq 2 ] && /bin/true

su -- vagrant -c 'mco choria request_cert'
