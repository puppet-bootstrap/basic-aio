# @summary Base OS customization
#
# @param packages A list of packages to manage
#
# @example
#   include profile::base
class profile::base (
  Array $packages,
) {
  package { $packages:
    ensure => installed,
  }
}
