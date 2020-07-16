# @summary Manage PuppetDB
#
# Manage PuppetDB
#
# @example
#   include profile::puppetserver::puppetdb
class profile::puppetserver::puppetdb {
  include 'puppetdb'

  if $facts['os']['family'] == 'RedHat' and Integer($facts['os']['release']['major']) >= 8 {
    # Without this, postgresql will not install.
    package { 'postgresql':
      ensure   => disabled,
      provider => 'dnfmodule',
    }

    Package['postgresql'] -> Class['puppetdb']
  }
}
