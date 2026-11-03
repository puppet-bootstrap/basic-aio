# @summary Configure OpenVoxDB
#
# Declares `bootstrap::db` with the same parameters the `bootstrap` Bolt
# plans use.  The first host in `profile::topology::db_servers` also runs
# PostgreSQL for the others.
#
# @param database_password Password for the OpenVoxDB PostgreSQL user
# @param postgres_version The PostgreSQL major version
# @param manage_firewall Open the OpenVoxDB (and, if needed, PostgreSQL) ports
#
# @example
#   include profile::db
class profile::db (
  Sensitive[String[1]] $database_password,
  String[1]            $postgres_version = '17',
  Boolean              $manage_firewall  = true,
) {
  include 'profile::topology'

  $postgres_host = $profile::topology::postgres_host
  $is_postgres_host = $trusted['certname'] == $postgres_host
  $remote_clients = $profile::topology::db_servers[1, -1]

  if $is_postgres_host {
    class { 'bootstrap::db':
      database_password     => $database_password,
      certificate_allowlist => $profile::topology::compilers,
      remote_clients        => $remote_clients,
      postgres_version      => $postgres_version,
    }
  } else {
    class { 'bootstrap::db':
      database_password     => $database_password,
      certificate_allowlist => $profile::topology::compilers,
      manage_dbserver       => false,
      database_host         => $postgres_host,
      postgres_version      => $postgres_version,
    }
  }

  if $manage_firewall {
    include 'firewalld'

    firewalld_port { 'openvoxdb':
      ensure   => present,
      zone     => 'public',
      port     => 8081,
      protocol => 'tcp',
    }

    if $is_postgres_host and !$remote_clients.empty {
      firewalld_port { 'postgresql':
        ensure   => present,
        zone     => 'public',
        port     => 5432,
        protocol => 'tcp',
      }
    }
  }
}
