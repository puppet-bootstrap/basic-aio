# role::puppetserver
#
# Puppet server class
#
# @summary Puppet server class
#
# @example
#   include role::puppetserver
class role::puppetserver {
  include 'git'
  include 'r10k'
  include 'puppetserver'
  include 'profile::puppetserver::config'
  include 'puppetdb'
  class { 'puppetdb::master::config':
    create_puppet_service_resource => false,
  }

  class { 'choria':
    manage_package_repo => true,
  }

  class { 'choria::broker':
    network_broker => true,
  }
}
