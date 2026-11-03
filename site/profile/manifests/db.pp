# @summary Configure db
#
# @example
#   include profile::db
class profile::db {
  include 'openvoxdb'
  include 'openvoxdb::master::config'

  if $facts['os']['family'] == 'RedHat' and Integer($facts['os']['release']['major']) > 7 {
    package { 'postgresql-dnfmodule':
      ensure   => disabled,
      name     => 'postgresql',
      provider => 'dnfmodule',
    }

    Package['postgresql-dnfmodule']
    -> Class['postgresql::server']
  }

  Class['openvoxdb']
  -> Class['openvoxdb::master::config']
}
