# @summary Install an OpenVox server infrastructure
#
# Installs the agent on every target, then sets up the certificate
# authority, OpenVoxDB, and compile masters.  The CA and OpenVoxDB can be on
# their own hosts or on the primary compile master.  It doesn't run the
# agent; see `bootstrap::first_run`.
#
# Order of operations:
#
# 1. Install the agent on every host and set `server` and `ca_server`.
# 2. Optionally add every host to every host's hosts file.
# 3. Set up the active CA.
# 4. Get signed certificates for the other infrastructure hosts.
# 5. Copy the CA directory to any standby CAs.
# 6. Set up OpenVoxDB.  The first OpenVoxDB host also runs PostgreSQL.
# 7. Set up the compile masters, with the CA service disabled on hosts that
#    aren't CAs.
#
# Every host's certname is the FQDN reported by its facts.
#
# @param targets The agent targets.  The infrastructure hosts are added to them.
# @param server_target The primary compile master
# @param compilers Additional compile masters
# @param ca_targets
#   The CA hosts.  The first is the active CA; any others are standbys with a
#   copy of its CA directory.  Defaults to `server_target`.
# @param db_targets
#   The OpenVoxDB hosts.  The first one also runs PostgreSQL.  OpenVoxDB isn't
#   installed if this is empty.
# @param db_password
#   Password for the OpenVoxDB PostgreSQL user.  Required if `db_targets` is
#   set.
# @param openvox_release The major version of OpenVox to install
# @param openvox_version
#   The version of openvox-agent to install.  Defaults to the latest version
#   in `openvox_collection`.  Installing openvox-server may upgrade the agent
#   on the server to satisfy openvox-server's dependencies.
# @param openvox_collection
#   The collection to install from.  Defaults to `openvox${openvox_release}`
#   when `openvox_release` is set; otherwise the `openvox_bootstrap::install`
#   task picks one.
# @param openvox_server
#   The value of `server` in `puppet.conf`.  Defaults to the FQDN of
#   `server_target`.  Set it to a load balancer name if you put one in front
#   of the compile masters (and add it to `dns_alt_names`).
# @param autosign
#   `true` to autosign every certificate request, or a list of certnames and
#   domain name globs to write to `autosign.conf` on the CAs.  `false` leaves
#   autosigning alone.
# @param dns_alt_names
#   Alternate DNS names for the compile masters' certificates.  These only
#   apply when a certificate is first issued.
# @param manage_firewall Open the needed ports in firewalld, if firewalld is running
# @param manage_hosts
#   Add every target to every target's hosts file, using the facts collected
#   from them.  Useful when the targets can't resolve each other's names.
# @param postgres_version The PostgreSQL major version to install
#
# @return [Hash] The certnames of the `primary`, `compilers` (including the
#   primary), `ca_servers` (active CA first), and `db_servers`, and the
#   `server` agents use.
plan bootstrap::install_infra (
  TargetSpec                                         $targets,
  TargetSpec                                         $server_target,
  TargetSpec                                         $compilers          = [],
  Optional[TargetSpec]                               $ca_targets         = undef,
  TargetSpec                                         $db_targets         = [],
  Optional[Variant[String[1], Sensitive[String[1]]]] $db_password        = undef,
  Optional[Integer]                                  $openvox_release    = undef,
  Optional[String[1]]                                $openvox_version    = undef,
  Optional[String[1]]                                $openvox_collection = $openvox_release ? {
    undef   => undef,
    default => "openvox${openvox_release}",
  },
  Optional[String[1]]                                $openvox_server     = undef,
  Variant[Boolean, Array[String[1]]]                 $autosign           = false,
  Array[String[1]]                                   $dns_alt_names      = [],
  Boolean                                            $manage_firewall    = false,
  Boolean                                            $manage_hosts       = false,
  String[1]                                          $postgres_version   = '17',
) {
  $database_password = $db_password ? {
    String  => Sensitive($db_password),
    default => $db_password,
  }

  $primary = get_targets($server_target)
  if $primary.length != 1 {
    fail_plan("server_target must be exactly one target (got ${primary.length})")
  }
  $servers = $primary + (get_targets($compilers) - $primary)
  $cas = $ca_targets ? {
    undef   => $primary,
    default => get_targets($ca_targets),
  }
  if $cas.empty {
    fail_plan('ca_targets must include at least one target')
  }
  $active_ca = $cas[0]
  $standby_cas = $cas[1, -1]
  $dbs = get_targets($db_targets)
  if !$dbs.empty and $db_password =~ Undef {
    fail_plan('db_password is required when db_targets is set')
  }
  $infra = ($servers + $cas + $dbs).unique
  $all = ($infra + get_targets($targets)).unique

  # 1. The agent everywhere
  $server = run_plan(
    'bootstrap::install_agents',
    'targets'            => $all,
    'server_target'      => $primary,
    'ca_target'          => $active_ca,
    'openvox_version'    => $openvox_version,
    'openvox_collection' => $openvox_collection,
    'openvox_server'     => $openvox_server,
  )

  $certname = $all.reduce({}) |$memo, $target| {
    $memo + { $target.name => $target.facts['networking']['fqdn'] }
  }
  $infra.each |$target| {
    if $certname[$target.name] !~ /\./ {
      fail_plan("${target.name} needs a fully qualified domain name to use as its certname (got '${certname[$target.name]}')")
    }
  }

  # 2. Hosts file
  if $manage_hosts {
    # Use the collected facts to build a hash of `host` resources.
    $hosts = $all.reduce({}) |$memo, $target| {
      $this_host = {
        $target.facts['networking']['fqdn'] => {
          'ip' => $target.facts['networking']['interfaces'].reduce('') |$m, $v| {
            if $v[0] =~ /^e/ and $v[1]['ip'] {
              $v[1]['ip']
            } else {
              $m
            }
          },
          'host_aliases' => [
            $target.facts['networking']['hostname'],
          ],
        },
      }
      $memo + $this_host
    }

    # Use the hash to configure the hosts file on each target.
    apply($all, '_description' => 'Configure hosts file') {
      $hosts.each |$key, $value| {
        host { $key:
          * => $value,
        }
      }
    }
  }

  # 3. The active CA
  $ca_server = run_plan(
    'bootstrap::install_ca',
    'targets'            => $active_ca,
    'server'             => $server,
    'openvox_collection' => $openvox_collection,
    'autosign'           => $autosign,
    'dns_alt_names'      => ($active_ca in $servers) ? {
      true    => $dns_alt_names,
      default => [],
    },
    'manage_firewall'    => $manage_firewall,
  )

  # 4. Certificates for the other infrastructure hosts
  run_plan(
    'bootstrap::request_certs',
    'targets'       => $servers - $active_ca,
    'ca_target'     => $active_ca,
    'dns_alt_names' => $dns_alt_names,
  )
  run_plan(
    'bootstrap::request_certs',
    'targets'   => ($standby_cas + $dbs).unique - $servers - $active_ca,
    'ca_target' => $active_ca,
  )

  # 5. Standby CAs.  The CA directory must be in place before puppetserver
  # first starts, or it would generate a new CA.
  unless $standby_cas.empty {
    run_task(
      'openvox_bootstrap::install',
      $standby_cas,
      'Installing openvox-server',
      'package'               => 'openvox-server',
      'collection'            => $openvox_collection,
      'force_release_package' => false,
    )
    run_plan('bootstrap::sync_ca', 'active' => $active_ca, 'standbys' => $standby_cas)

    $standalone_standbys = $standby_cas - $servers
    unless $standalone_standbys.empty {
      if $manage_firewall {
        run_plan('bootstrap::open_ports', 'targets' => $standalone_standbys, 'ports' => [8140])
      }
      apply($standalone_standbys, '_description' => 'Configuring standby CAs') {
        class { 'bootstrap::server':
          ca_enabled => true,
          server     => $server,
          ca_server  => $ca_server,
        }
        class { 'bootstrap::ca':
          autosign => $autosign,
        }
      }
    }
  }

  # 6. OpenVoxDB
  $puppetdb_urls = $dbs.empty ? {
    true    => [],
    default => run_plan(
      'bootstrap::install_db',
      'targets'               => $dbs,
      'database_password'     => $database_password,
      'certificate_allowlist' => $servers.map |$target| { $certname[$target.name] },
      'postgres_version'      => $postgres_version,
      'manage_firewall'       => $manage_firewall,
    ),
  }

  # 7. Compile masters
  run_plan(
    'bootstrap::install_server',
    'targets'            => $servers,
    'ca_server'          => $ca_server,
    'server'             => $server,
    'ca_targets'         => $cas,
    'openvox_collection' => $openvox_collection,
    'puppetdb_urls'      => $puppetdb_urls,
    'manage_firewall'    => $manage_firewall,
  )

  # CAs on compile masters also need the CA configuration.
  $server_cas = $cas.filter |$target| { $target in $servers }
  unless $server_cas.empty {
    apply($server_cas, '_description' => 'Configuring the CA on compile masters') {
      class { 'bootstrap::server':
        ca_enabled => true,
        server     => $server,
        ca_server  => $ca_server,
      }
      unless $puppetdb_urls.empty {
        class { 'bootstrap::server::puppetdb':
          puppetdb_urls => $puppetdb_urls,
        }
      }
      class { 'bootstrap::ca':
        autosign => $autosign,
      }
    }
  }

  $topology = {
    'server'     => $server,
    'primary'    => $certname[$primary[0].name],
    'compilers'  => $servers.map |$target| { $certname[$target.name] },
    'ca_servers' => $cas.map |$target| { $certname[$target.name] },
    'db_servers' => $dbs.map |$target| { $certname[$target.name] },
  }

  return $topology
}
