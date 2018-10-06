#!/bin/bash

set -e

# Bootstrap the puppet module configuration
# Source the profile to get the path
. /etc/profile.d/puppet-agent.sh
puppet module install puppet/r10k
puppet apply /vagrant/bootstrap.pp
puppet apply -e 'include ["puppetserver", "profile::puppetserver::config"]'
