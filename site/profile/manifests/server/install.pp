# @summary Install server package
#
# @param package The name of the package to install
# @param package_ensure The ensure value for the package
#
# @example
#   include profile::server::install
class profile::server::install (
  String[1] $package        = 'openvox-server',
  String[1] $package_ensure = 'installed',
) {
  package { $package:
    ensure => $package_ensure,
  }
}
