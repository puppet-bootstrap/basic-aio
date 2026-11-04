# @summary Check that the targets are ready for `bootstrap` without changing them
#
# Takes the same target and repository parameters as `bootstrap` (and
# `bootstrap::install_infra`) and checks each target without changing
# anything:
#
# * Bolt can connect, with root access
# * Infrastructure hosts have a fully qualified hostname (their certname)
# * No two targets have the same hostname
# * Clocks are within a minute of the Bolt host's
# * The names each target will use resolve: the server and active CA on every
#   target, and every infrastructure host on the infrastructure hosts
#   (except names that `manage_hosts` or `alias_server_names` will add to the
#   hosts file)
# * With `manage_repos`, yum.voxpupuli.org (and, for OpenVoxDB with `pgdg`,
#   download.postgresql.org) is reachable
# * Without `manage_repos`, the OpenVox packages each target needs are
#   available from its configured repositories
# * The PostgreSQL packages (or module stream) are available on the first
#   OpenVoxDB host, unless they'll come from the PGDG repository the plans set
#   up
#
# Package checks use dnf, so they only run on EL hosts.  The plan reports
# every problem it finds and then fails if there were any.
#
# @param targets The agent targets.  The infrastructure hosts are added to them.
# @param server_target The primary compile master
# @param compilers Additional compile masters
# @param ca_targets The CA hosts.  Defaults to `server_target`.
# @param db_targets The OpenVoxDB hosts
# @param openvox_server
#   The value of `server` in `puppet.conf`.  Defaults to the FQDN of
#   `server_target`.
# @param manage_repos Whether the bootstrap will set up package repositories
# @param manage_hosts Whether the bootstrap will add every target to every target's hosts file
# @param alias_server_names
#   Whether the bootstrap will add `openvox_server` to every target's hosts
#   file
# @param postgres_source Where PostgreSQL will come from (`pgdg` or `os`)
# @param postgres_version
#   The PostgreSQL major version.  Defaults to `17` with `pgdg` and `16` with
#   `os`.
# @param server_urls
#   Additional URLs the compile masters must be able to reach, such as
#   https://rubygems.org and https://forge.puppet.com for deploying a control
#   repo with r10k
#
# @return [Hash] Each target's FQDN, errors, and warnings
plan bootstrap::preflight (
  TargetSpec           $targets,
  TargetSpec           $server_target,
  TargetSpec           $compilers          = [],
  Optional[TargetSpec] $ca_targets         = undef,
  TargetSpec           $db_targets         = [],
  Optional[String[1]]  $openvox_server     = undef,
  Boolean              $manage_repos       = true,
  Boolean              $manage_hosts       = false,
  Boolean              $alias_server_names = false,
  Enum['pgdg', 'os']   $postgres_source    = 'pgdg',
  Optional[String[1]]  $postgres_version   = undef,
  Array[String[1]]     $server_urls        = [],
) {
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
  $dbs = get_targets($db_targets)
  $infra = ($servers + $cas + $dbs).unique
  $all = ($infra + get_targets($targets)).unique

  # Connect to every target, and collect its hostname and clock.
  $started = Integer(Timestamp.new.strftime('%s'))
  $basics = run_command(
    'hostname -f 2>/dev/null || hostname; date +%s',
    $all,
    'Connecting to the targets',
    '_catch_errors' => true,
  )
  $finished = Integer(Timestamp.new.strftime('%s'))

  $reachable = $basics.ok_set.targets
  $unreachable = $basics.error_set.reduce({}) |$memo, $result| {
    $memo + { $result.target.name => [$result.error.message] }
  }

  $basic = $basics.ok_set.reduce({}) |$memo, $result| {
    $lines = $result['stdout'].strip.split("\n")
    $memo + { $result.target.name => { 'fqdn' => $lines[0].strip, 'time' => Integer($lines[-1].strip) } }
  }
  $fqdn = $basic.reduce({}) |$memo, $entry| { $memo + { $entry[0] => $entry[1]['fqdn'] } }

  # Duplicate hostnames would mean duplicate certnames.
  $duplicates = $fqdn.reduce({}) |$memo, $entry| {
    $others = $fqdn.filter |$name, $other| { $name != $entry[0] and $other == $entry[1] }
    $others.empty ? {
      true    => $memo,
      default => $memo + { $entry[0] => ["${entry[1]} is also the hostname of ${others.keys.join(', ')}"] },
    }
  }

  # Clocks more than a minute off can make new certificates invalid.
  $skewed = $basic.reduce({}) |$memo, $entry| {
    $time = $entry[1]['time']
    if $time < $started - 60 or $time > $finished + 60 {
      $memo + { $entry[0] => ["The clock is ${time - $finished} seconds off from the Bolt host's"] }
    } else {
      $memo
    }
  }

  # The names that will be in hosts files, which don't need to resolve yet.
  $primary_fqdn = $fqdn[$primary[0].name]
  $server_name = pick($openvox_server, $primary_fqdn, $primary[0].name)
  $active_ca_fqdn = pick($fqdn[$cas[0].name], $cas[0].name)
  $infra_fqdns = $infra.map |$target| { pick($fqdn[$target.name], $target.name) }
  $managed_hosts_names = $manage_hosts ? {
    true    => $fqdn.values,
    default => [],
  }
  $aliased_names = $alias_server_names ? {
    true    => [$primary_fqdn, $server_name],
    default => [],
  }
  $hosts_names = $managed_hosts_names + $aliased_names

  $postgres_host = $dbs.empty ? {
    true    => undef,
    default => $dbs[0],
  }
  $infra_names = $infra.map |$target| { $target.name }
  $server_names = $servers.map |$target| { $target.name }
  $server_or_ca_names = ($servers + $cas).map |$target| { $target.name }
  $db_names = $dbs.map |$target| { $target.name }

  $task_results = parallelize($reachable) |$target| {
    $name = $target.name
    $is_infra = $name in $infra_names

    $needed = $is_infra ? {
      true    => [$server_name, $active_ca_fqdn] + $infra_fqdns,
      default => [$server_name, $active_ca_fqdn],
    }
    $resolve = ($needed.unique - $hosts_names - [$fqdn[$name]]).filter |$n| { $n =~ NotUndef }

    $is_postgres_host = $postgres_host =~ NotUndef and $name == $postgres_host.name
    $check_postgres = $is_postgres_host and ($postgres_source == 'os' or !$manage_repos)

    if $manage_repos {
      $packages = []
      $repo_urls = $is_postgres_host and $postgres_source == 'pgdg' ? {
        true    => ['https://yum.voxpupuli.org/', 'https://download.postgresql.org/pub/repos/yum/'],
        default => ['https://yum.voxpupuli.org/'],
      }
    } else {
      $packages = [
        'openvox-agent',
        if $name in $server_or_ca_names { 'openvox-server' },
        if $name in $db_names { 'openvoxdb' },
        if $name in $server_names and !$dbs.empty { 'openvoxdb-termini' },
      ].filter |$p| { $p =~ NotUndef }
      $repo_urls = []
    }

    $urls = $name in $server_names ? {
      true    => $repo_urls + $server_urls,
      default => $repo_urls,
    }

    $params = {
      'require_fqdn'     => $is_infra,
      'resolve'          => $resolve.join(' '),
      'packages'         => $packages.join(' '),
      'postgres_source'  => $check_postgres ? { true => $postgres_source, default => undef },
      'postgres_version' => $check_postgres ? { true => $postgres_version, default => undef },
      'urls'             => $urls.join(' '),
    }.filter |$key, $value| { $value =~ NotUndef }

    run_task('bootstrap::preflight', $target, "Checking ${name}", $params + { '_catch_errors' => true }).first
  }

  $report = $all.reduce({}) |$memo, $target| {
    $name = $target.name
    $result = $task_results.filter |$r| { $r.target.name == $name }[0]
    if $result =~ Undef {
      $task_errors = []
      $task_warnings = []
    } elsif $result.ok {
      $task_errors = $result['errors']
      $task_warnings = $result['warnings']
    } else {
      $task_errors = ["The preflight task failed: ${result.error.message}"]
      $task_warnings = []
    }
    $memo + {
      $name => {
        'fqdn'     => $fqdn[$name],
        'errors'   => pick($unreachable[$name], []) + pick($duplicates[$name], []) + $task_errors,
        'warnings' => pick($skewed[$name], []) + $task_warnings,
      },
    }
  }

  $report.each |$name, $checks| {
    $status = $checks['errors'].empty ? {
      true    => 'OK',
      default => 'FAILED',
    }
    out::message("${status}: ${name} (${pick($checks['fqdn'], 'unknown')})")
    $checks['errors'].each |$message| { out::message("  error: ${message}") }
    $checks['warnings'].each |$message| { out::message("  warning: ${message}") }
  }

  $error_count = $report.values.map |$checks| { $checks['errors'].length }.reduce(0) |$sum, $n| { $sum + $n }
  if $error_count > 0 {
    fail_plan("Preflight found ${error_count} problem(s)", 'bootstrap/preflight-failed', $report)
  }

  return $report
}
