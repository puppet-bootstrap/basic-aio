# @summary Agent class
#
# @example
#   include role::agent
class role::agent {
  include 'profile::base'
  include 'profile::agent'
  include 'mcollective'
}
