# role::puppetserver
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include role::puppetserver
class role::puppetserver {
  include '::r10k'
  include '::puppetdb'
  include '::puppetdb::master::config'

  class { '::choria':
    manage_package_repo => true,
  }

  class { '::choria::broker':
    network_broker => true,
  }
}
