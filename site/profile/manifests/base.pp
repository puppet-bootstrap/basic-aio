# profile::base
#
# Base OS customization
#
# @summary Base OS customization
#
# @example
#   include profile::base
class profile::base (
  Array $packages,
){
  package { $packages:
    ensure => installed,
  }
}
