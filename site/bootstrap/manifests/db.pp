# @summary Configure OpenVoxDB, optionally with a local PostgreSQL server
#
# A thin wrapper around the `openvoxdb` class from puppet/openvoxdb.  The
# first OpenVoxDB host runs PostgreSQL (`manage_dbserver => true`); any other
# OpenVoxDB hosts set `database_host` to it and are listed in its
# `remote_clients`.
#
# @param database_password Password for the OpenVoxDB PostgreSQL user
# @param certificate_allowlist
#   Certnames allowed to connect to OpenVoxDB over HTTPS, normally every
#   compile master.
# @param manage_dbserver Install and manage PostgreSQL on this host
# @param database_host The PostgreSQL host, as seen from this host
# @param remote_clients
#   Other OpenVoxDB hosts that connect to the PostgreSQL server on this host.
#   They must be able to resolve each other's names.
# @param postgres_version The PostgreSQL major version to install from the PGDG repo
#
# @example
#   class { 'bootstrap::db':
#     database_password     => Sensitive('secret'),
#     certificate_allowlist => ['puppet.example.com'],
#   }
class bootstrap::db (
  Sensitive[String[1]] $database_password,
  Array[String[1]]     $certificate_allowlist = [],
  Boolean              $manage_dbserver       = true,
  Stdlib::Host         $database_host         = 'localhost',
  Array[String[1]]     $remote_clients        = [],
  String[1]            $postgres_version      = '17',
) {
  $remote = $manage_dbserver and !$remote_clients.empty
  $listen_address = $remote ? {
    true    => '0.0.0.0',
    default => 'localhost',
  }

  class { 'openvoxdb':
    manage_dbserver         => $manage_dbserver,
    manage_database         => $manage_dbserver,
    database_host           => $database_host,
    database_password       => $database_password,
    database_listen_address => $listen_address,
    certificate_whitelist   => $certificate_allowlist,
    postgres_version        => $postgres_version,
    manage_firewall         => false,
  }

  # EL 8 and 9 ship a postgresql module stream that can mask the PGDG
  # packages.  (EL 10 has no module streams.)
  if $manage_dbserver and $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] in ['8', '9'] {
    package { 'postgresql-dnfmodule':
      ensure   => disabled,
      name     => 'postgresql',
      provider => 'dnfmodule',
      before   => Class['postgresql::server'],
    }
  }

  if $remote {
    $remote_clients.each |$client| {
      postgresql::server::pg_hba_rule { "openvoxdb on ${client}":
        type        => 'host',
        database    => 'puppetdb',
        user        => 'puppetdb',
        address     => $client,
        auth_method => 'scram-sha-256',
        order       => 100,
      }
    }
  }
}
