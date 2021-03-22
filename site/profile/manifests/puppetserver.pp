# @summary Configure puppetserver
#
# @example
#   include profile::puppetserver
class profile::puppetserver {
  include 'profile::puppetserver::install'
  include 'profile::puppetserver::config'
  include 'profile::puppetserver::service'

  Class['profile::puppetserver::install']
  -> Class['profile::puppetserver::config']
  ~> Class['profile::puppetserver::service']
}
