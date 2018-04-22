# profile::puppetserver
#
# Configures the Puppet server
#
# @summary Configures the Puppet server
#
# @example
#   include profile::puppetserver
class profile::puppetserver {
  contain '::profile::puppetserver::install'
  contain '::profile::puppetserver::config'
  contain '::profile::puppetserver::service'

  Class['::profile::puppetserver::install']
  -> Class['::profile::puppetserver::config']
  ~> Class['::profile::puppetserver::service']
}
