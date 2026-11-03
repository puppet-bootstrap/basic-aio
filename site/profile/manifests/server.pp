# @summary Configure OpenVox Server on a compile master or CA host
#
# Declares `bootstrap::server` (and `bootstrap::server::puppetdb` on compile
# masters) with the same parameters the `bootstrap` Bolt plans use, so Puppet
# keeps the configuration they set up.
#
# @param manage_firewall Manage the server firewall configuration
#
# @example
#   include profile::server
class profile::server (
  Boolean $manage_firewall = true,
) {
  include 'profile::topology'

  if $manage_firewall {
    include 'firewalld'

    firewalld_service { 'puppetmaster':
      ensure  => present,
      zone    => 'public',
      service => 'puppetmaster',
    }
  }

  class { 'bootstrap::server':
    ca_enabled => $profile::topology::is_ca,
    server     => $profile::topology::server,
    ca_server  => $profile::topology::active_ca,
  }

  if $profile::topology::is_compiler and !$profile::topology::db_servers.empty {
    class { 'bootstrap::server::puppetdb':
      puppetdb_urls => $profile::topology::puppetdb_urls,
    }
  }
}
