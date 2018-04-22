# profile::puppetserver::install
#
# Install the Puppet server
#
# @summary Install the Puppet server
#
# @example
#   include profile::puppetserver::install
class profile::puppetserver::install (
  Variant[String, Array[String]] $package,
){
  package { $package:
    ensure => installed,
  }
}
