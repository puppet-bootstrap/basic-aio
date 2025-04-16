# @summary Puppet server class
#
# @example
#   include role::server
class role::server {
  include 'git'
  include 'r10k'

  include 'profile::server'

  include 'profile::puppetdb'

  include 'choria'
  include 'choria::broker'
}
