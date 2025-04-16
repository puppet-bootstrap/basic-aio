# @summary Configure server
#
# @param manage_firewall Manage the server firewall configuration
#
# @example
#   include profile::server
class profile::server (
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

  include 'profile::server::install'
  include 'profile::server::config'
  include 'profile::server::service'

  Class['profile::server::install']
  -> Class['profile::server::config']
  ~> Class['profile::server::service']
}
