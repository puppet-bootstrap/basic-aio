# profile::puppetserver::service
#
# Manage the Puppet server service
#
# @summary Manage the Puppet server service
#
# @example
#   include profile::puppetserver::service
class profile::puppetserver::service (
  Variant[String, Array[String]] $service,
){
  service { $service:
    ensure => running,
    enable => true,
  }
}
