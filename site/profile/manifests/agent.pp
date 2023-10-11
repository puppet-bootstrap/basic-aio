# @summary Configures the `puppet` service
#
# @param service Puppet agent service name
# @param service_ensure The `ensure` attribute for the agent service
# @param service_enable The `enable` attribute for the agent service
#
# @example
#   include profile::agent
class profile::agent (
  Variant[String, Array[String]] $service,
  String $service_ensure,
  Boolean $service_enable,
) {
  service { $service:
    ensure => $service_ensure,
    enable => $service_enable,
  }
}
