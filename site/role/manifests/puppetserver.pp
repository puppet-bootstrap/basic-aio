# role::puppetserver
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include role::puppetserver
class role::puppetserver {
  include 'r10k'
  include 'puppetserver'
  include 'profile::puppetserver::config'
  include 'puppetdb'
  class { 'puppetdb::master::config':
    create_puppet_service_resource => false,
  }
}
