# @summary Install and configure OpenVoxDB
#
# The first target runs PostgreSQL (from the PGDG repo) as well as OpenVoxDB.
# Any other targets run OpenVoxDB against that PostgreSQL server, so the
# targets must be able to resolve each other's names.  The targets need
# signed certificates first (see `bootstrap::request_certs`).
#
# @param targets The OpenVoxDB hosts
# @param database_password Password for the OpenVoxDB PostgreSQL user
# @param certificate_allowlist
#   Certnames allowed to connect to OpenVoxDB, normally every compile master
# @param postgres_version The PostgreSQL major version to install
# @param manage_firewall
#   Open 8081/tcp (and 5432/tcp on the PostgreSQL host, if needed) in
#   firewalld, if firewalld is running
# @param manage_repos
#   Set up the PostgreSQL (PGDG) package repository.  Set this to `false` on
#   hosts that can't reach the internet but already have the PGDG packages
#   available, such as from a Satellite.
#
# @return [Array[String]] OpenVoxDB URLs for the compile masters' `puppetdb.conf`
plan bootstrap::install_db (
  TargetSpec           $targets,
  Sensitive[String[1]] $database_password,
  Array[String[1]]     $certificate_allowlist = [],
  String[1]            $postgres_version      = '17',
  Boolean              $manage_firewall       = false,
  Boolean              $manage_repos          = true,
) {
  $db = get_targets($targets)
  if $db.empty {
    return []
  }

  apply_prep($db)
  $certnames = $db.map |$target| { $target.facts['networking']['fqdn'] }
  $postgres_host = $certnames[0]
  $remote_clients = $certnames[1, -1]

  if $manage_firewall {
    run_plan('bootstrap::open_ports', 'targets' => $db, 'ports' => [8081])
    unless $remote_clients.empty {
      run_plan('bootstrap::open_ports', 'targets' => $db[0], 'ports' => [5432])
    }
  }

  # Set up the PostgreSQL host first so the others can connect to it.
  apply($db[0], '_description' => "Configuring OpenVoxDB and PostgreSQL on ${postgres_host}") {
    class { 'bootstrap::db':
      database_password     => $database_password,
      certificate_allowlist => $certificate_allowlist,
      remote_clients        => $remote_clients,
      postgres_version      => $postgres_version,
      manage_package_repo   => $manage_repos,
    }
  }

  unless $remote_clients.empty {
    apply($db[1, -1], '_description' => 'Configuring OpenVoxDB') {
      class { 'bootstrap::db':
        database_password     => $database_password,
        certificate_allowlist => $certificate_allowlist,
        manage_dbserver       => false,
        database_host         => $postgres_host,
        postgres_version      => $postgres_version,
        manage_package_repo   => $manage_repos,
      }
    }
  }

  return $certnames.map |$certname| { "https://${certname}:8081" }
}
