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
# @param postgres_source
#   Where PostgreSQL comes from.  `pgdg` installs the PGDG packages (such as
#   `postgresql17-server`).  `os` installs the operating system's packages
#   (`postgresql-server`); on EL 8 and 9, it enables the AppStream
#   `postgresql` module stream for `postgres_version`.
# @param postgres_version
#   The PostgreSQL major version.  Defaults to `17` with `pgdg` and `16` with
#   `os`.  OpenVoxDB needs PostgreSQL 14 or later.  With `os` on EL 8 and 9,
#   this is the module stream to enable (EL 9 has 15, 16, and 18).  With `os`
#   on EL 10, versions other than 16 use the versioned packages (such as
#   `postgresql18-server`).
# @param manage_package_repo
#   Set up the PGDG package repository.  Without it, the PGDG packages must
#   already be available from a configured repository.  Ignored with `os`.
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
  Enum['pgdg', 'os']   $postgres_source       = 'pgdg',
  Optional[String[1]]  $postgres_version      = undef,
  Boolean              $manage_package_repo   = true,
) {
  $version = pick($postgres_version, $postgres_source ? {
    'os'    => '16',
    default => '17',
  })
  $os_postgres = $postgres_source == 'os'
  $el_with_modules = $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] in ['8', '9']

  # EL 10 has no module streams.  Its other PostgreSQL versions are packages
  # such as `postgresql18-server`, with the same paths and service as the
  # default version's packages.  puppetlabs/postgresql would use PGDG paths
  # for them.
  $el10_versioned = $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] == '10' and $version != '16'
  $versioned_settings = $el10_versioned ? {
    true    => {
      'client_package_name'  => "postgresql${version}",
      'server_package_name'  => "postgresql${version}-server",
      'contrib_package_name' => "postgresql${version}-contrib",
      'bindir'               => '/usr/bin',
      'datadir'              => '/var/lib/pgsql/data',
      'confdir'              => '/var/lib/pgsql/data',
      'service_name'         => 'postgresql',
    },
    default => {},
  }
  $remote = $manage_dbserver and !$remote_clients.empty
  $listen_address = $remote ? {
    true    => '0.0.0.0',
    default => 'localhost',
  }

  # puppet/openvoxdb always sets up PostgreSQL for the PGDG packages (it
  # turns off postgresql::globals' `manage_dnf_module`, which also selects the
  # operating system's package names).  For the operating system's packages,
  # let it create only the database, and set up the server here instead.
  if $manage_dbserver and $os_postgres {
    class { 'postgresql::globals':
      manage_dnf_module   => $el_with_modules,
      manage_package_repo => false,
      version             => $version,
      *                   => $versioned_settings,
    }

    # The same settings puppet/openvoxdb uses.
    class { 'postgresql::server':
      ip_mask_allow_all_users => '0.0.0.0/0',
      listen_addresses        => $listen_address,
      port                    => 5432,
      password_encryption     => 'scram-sha-256',
    }

    class { 'postgresql::server::contrib': }

    postgresql::server::extension { 'pg_trgm':
      database => 'puppetdb',
      port     => 5432,
      require  => Postgresql::Server::Db['puppetdb'],
    }
  }

  class { 'openvoxdb':
    manage_dbserver         => $manage_dbserver and !$os_postgres,
    manage_database         => $manage_dbserver,
    database_host           => $database_host,
    database_password       => $database_password,
    database_listen_address => $listen_address,
    certificate_whitelist   => $certificate_allowlist,
    postgres_version        => $version,
    manage_package_repo     => $manage_package_repo and !$os_postgres,
    manage_firewall         => false,
  }

  # EL 8 and 9 ship a postgresql module stream that can mask the PGDG
  # packages.  (EL 10 has no module streams.)
  if $manage_dbserver and !$os_postgres and $el_with_modules {
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
