# @summary The layout of the OpenVox infrastructure
#
# The `basic_aio` Bolt plan writes the real values into the global Hiera
# layer on the compile masters.  The environment's `data/common.yaml` has
# defaults for the all-in-one demo.
#
# @param primary The certname of the primary compile master
# @param server The `server` setting that agents use
# @param compilers The certnames of every compile master, including the primary
# @param ca_servers The certnames of the CA hosts.  The first is the active CA.
# @param db_servers
#   The certnames of the OpenVoxDB hosts.  The first one also runs PostgreSQL.
#
# @example
#   include profile::topology
class profile::topology (
  String[1]           $primary,
  String[1]           $server,
  Array[String[1], 1] $compilers,
  Array[String[1], 1] $ca_servers,
  Array[String[1]]    $db_servers,
) {
  $certname = $trusted['certname']

  $infrastructure = ($compilers + $ca_servers + $db_servers).unique
  $is_primary = $certname == $primary
  $is_compiler = $certname in $compilers
  $is_ca = $certname in $ca_servers
  $is_db = $certname in $db_servers

  $active_ca = $ca_servers[0]
  $postgres_host = $db_servers[0]
  $puppetdb_urls = $db_servers.map |$db| { "https://${db}:8081" }
}
