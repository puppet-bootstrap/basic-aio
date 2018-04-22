# profile::agent
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
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
