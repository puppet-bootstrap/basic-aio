# @summary Configure server service
#
# @param service_name The name of the service to manage
# @param service_ensure The ensure value for the service
# @param service_enable Whether to enable the service at boot
#
# @example
#   include profile::server::service
class profile::server::service (
  String[1] $service_name   = 'puppetserver',
  String[1] $service_ensure = 'running',
  Boolean   $service_enable = true,
) {
  service { $service_name:
    ensure => $service_ensure,
    enable => $service_enable,
  }
}
