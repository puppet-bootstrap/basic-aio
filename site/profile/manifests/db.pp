# @summary Configure db
#
# @example
#   include profile::db
class profile::db {
  include 'puppetdb'
  include 'puppetdb::master::config'

  if $facts['os']['family'] == 'RedHat' and Integer($facts['os']['release']['major']) > 7 {
    package { 'postgresql-dnfmodule':
      ensure   => disabled,
      name     => 'postgresql',
      provider => 'dnfmodule',
    }

    Package['postgresql-dnfmodule']
    -> Class['postgresql::server']
  }

  Class['puppetdb']
  -> Class['puppetdb::master::config']
}
