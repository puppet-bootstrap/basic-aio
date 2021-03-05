# @summary Configure puppetdb
#
# @example
#   include profile::puppetdb
class profile::puppetdb {
  include 'puppetdb'
  include 'puppetdb::master::config'

  if $facts['os']['family'] == 'RedHat' and Integer($facts['os']['release']['major']) > 7 {
    package { 'postgresql-dnfmodule':
      ensure   => disabled,
      name     => 'postgresql',
      provider => 'dnfmodule',
    }

    Package['postgresql-dnfmodule']
    -> Class['puppetdb']
  }

  Class['puppetdb']
  -> Class['puppetdb::master::config']
}
