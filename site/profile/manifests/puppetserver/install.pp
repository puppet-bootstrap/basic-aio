# @summary Install puppetserver package
#
# @example
#   include profile::puppetserver::install
class profile::puppetserver::install {
  package { 'puppetserver':
    ensure => installed,
  }
}
