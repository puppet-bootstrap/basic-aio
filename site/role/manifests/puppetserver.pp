# role::puppetserver
#
# Puppet server class
#
# @summary Puppet server class
#
# @example
#   include role::puppetserver
class role::puppetserver {
  include 'git'
  include 'r10k'

  include 'puppetserver'
  include 'profile::puppetserver::config'

  include 'profile::puppetdb'

  include 'choria'
  include 'choria::broker'
}
