# @summary Configure puppetserver
#
# @param manage_firewall Manage the puppetserver firewall configuration
#
# @example
#   include profile::puppetserver
class profile::puppetserver (
  Boolean $manage_firewall = true,
) {
  if $manage_firewall {
    include 'firewalld'

    firewalld_service { 'puppetmaster':
      ensure  => present,
      zone    => 'public',
      service => 'puppetmaster',
    }
  }

  include 'profile::puppetserver::install'
  include 'profile::puppetserver::config'
  include 'profile::puppetserver::service'

  Class['profile::puppetserver::install']
  -> Class['profile::puppetserver::config']
  ~> Class['profile::puppetserver::service']
}
