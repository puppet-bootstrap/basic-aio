# profile::puppetserver::service
#
# Manage the Puppet server service
#
# @summary Manage the Puppet server service
#
# @example
#   include profile::puppetserver::service
class profile::puppetserver::service {
  contain '::puppetdb::master::config'
}
