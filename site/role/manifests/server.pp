# @summary OpenVox infrastructure host
#
# Applied to every compile master, CA, and OpenVoxDB host.  Which profiles
# apply depends on the host's place in `profile::topology`.
#
# @example
#   include role::server
class role::server {
  include 'profile::topology'

  if $profile::topology::is_compiler or $profile::topology::is_ca {
    include 'profile::server'
  }

  if $profile::topology::is_ca {
    include 'profile::ca'
  }

  if $profile::topology::is_compiler {
    include 'git'
    include 'r10k'
  }

  if $profile::topology::is_db {
    include 'profile::db'
  }

  include 'choria'

  if $profile::topology::is_primary {
    include 'choria::broker'
  }
}
