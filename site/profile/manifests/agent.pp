# profile::agent
#
# Configures the `puppet` service
#
# @summary Configures the `puppet` service
#
# @example
#   include profile::agent
class profile::agent (
  Variant[String, Array[String]] $service,
  String $service_ensure,
  Boolean $service_enable,
){
  service { $service:
    ensure => $service_ensure,
    enable => $service_enable,
  }
}
