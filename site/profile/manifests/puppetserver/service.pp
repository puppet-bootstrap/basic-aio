# @summary Configure puppetserver service
#
# @example
#   include profile::puppetserver::service
class profile::puppetserver::service {
  service { 'puppetserver':
    ensure => running,
    enable => true,
  }
}
