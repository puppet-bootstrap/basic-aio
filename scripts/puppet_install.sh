#!/bin/bash

set -e

# Source the profile to get the path
. /etc/profile.d/puppet-agent.sh

# FIXME: This should be moved into Puppet code
if [ "$( facter os.release.major )" -gt 7 ] ; then
    # Without this, puppetserver can't communicate with puppetdb.
    update-crypto-policies --set LEGACY
fi

# Bootstrap the puppet module configuration
puppet module install puppet/r10k
puppet apply /vagrant/bootstrap.pp
puppet apply -e 'include ["puppetserver", "profile::puppetserver::config"]'
