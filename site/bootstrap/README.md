# bootstrap

[OpenBolt](https://github.com/OpenVoxProject/openbolt) plans to stand up an
OpenVox infrastructure (CA, OpenVoxDB, and compile masters) and agents on
existing hosts.  Everything can run on one host, or the CA, OpenVoxDB, and
extra compile masters can each have their own hosts.

The plans use the tasks in
[puppet/openvox_bootstrap](https://github.com/voxpupuli/puppet-openvox_bootstrap)
to install packages and configure the agent, and the Puppet classes in this
module (applied with Bolt's `apply()`) to configure the infrastructure.  A
control repo can include the same classes to keep managing that
configuration after the bootstrap.

## Plans

* `bootstrap`: runs `bootstrap::install_infra` and then
  `bootstrap::first_run` (and `bootstrap::smoke_test` with more than one
  compile master).
* `bootstrap::install_infra`: installs the agent everywhere, then sets up the
  active CA, certificates for the other infrastructure hosts, standby CAs,
  OpenVoxDB, and the compile masters.  Returns the layout (certnames of each
  kind of host).
* `bootstrap::install_agents`: installs openvox-agent, collects facts, and sets
  `server` (and `ca_server`) in `puppet.conf`.  The puppet service is left
  stopped.
* `bootstrap::install_ca`: installs openvox-server, creates the CA with
  `puppetserver ca setup`, and starts it.
* `bootstrap::request_certs`: requests, signs, and downloads certificates for
  hosts that aren't the CA.
* `bootstrap::sync_ca`: copies the CA directory from the active CA to standby
  CAs.  Rerun it after the active CA signs or revokes certificates.
* `bootstrap::copy_cert`: moves certificates generated on the CA (for standby
  CAs, by the `bootstrap::ca_generate` task) to the hosts they belong to.
* `bootstrap::install_db`: sets up OpenVoxDB, with PostgreSQL (from the PGDG
  repo) on the first OpenVoxDB host.
* `bootstrap::install_server`: sets up compile masters, with the CA service
  disabled on hosts that aren't CAs, and connects them to OpenVoxDB.
* `bootstrap::first_run`: runs the agent on the server, then on the other
  targets.  For agents whose first run fails because their certificate isn't
  signed yet, it signs their certificate requests on the CA and runs them
  again.  Then it starts the puppet service.
* `bootstrap::smoke_test`: runs the agent in no-op mode on every target against
  each compile master.
* `bootstrap::open_ports`: opens TCP ports in firewalld.

If you need to do something between those steps, such as deploying code to
the compile masters, call the individual plans yourself.  This repo's
`basic_aio` plan does that to set up r10k before the first agent run.

## Classes

* `bootstrap::server`: openvox-server, with the CA service enabled or
  disabled, and a systemd path unit that reloads puppetserver when the CRL
  changes on hosts without the CA service.
* `bootstrap::server::puppetdb`: `puppetdb.conf` (with one or more OpenVoxDB
  URLs), `routes.yaml`, `storeconfigs`, and `reports`.
* `bootstrap::ca`: `ca.conf` (allowing DNS alt names) and autosigning.
* `bootstrap::db`: OpenVoxDB via puppet/openvoxdb, with a local or remote
  PostgreSQL server.

See [REFERENCE.md](REFERENCE.md) for parameters.

## Examples

Everything on one host:

```sh
bolt plan run bootstrap \
  --targets server.example.com,agent1.example.com,agent2.example.com \
  server_target=server.example.com \
  openvox_release=9 \
  manage_firewall=true \
  --run-as root
```

A separate active and standby CA, two OpenVoxDB hosts, and two compile
masters behind a load balancer:

```sh
bolt plan run bootstrap \
  --targets agent1.example.com,agent2.example.com \
  server_target=compile1.example.com \
  compilers=compile2.example.com \
  ca_targets=ca1.example.com,ca2.example.com \
  db_targets=db1.example.com,db2.example.com \
  db_password="$OPENVOXDB_PASSWORD" \
  openvox_server=puppet.example.com \
  dns_alt_names='["puppet.example.com"]' \
  manage_firewall=true \
  --run-as root
```

To make `openvox_server` and the `dns_alt_names` resolve to `server_target`
without DNS, add `alias_server_names=true`.  Every target's hosts file then
lists them as aliases of `server_target`.  Rerunning the plan without
`alias_server_names` doesn't remove those entries.

## Airgapped hosts

By default, the plans install the `openvoxN-release` package from
yum.voxpupuli.org (or apt.voxpupuli.org) to set up the OpenVox repository, and
OpenVoxDB's PostgreSQL comes from the PGDG repository at
download.postgresql.org.  On hosts that can't reach those but already have the
packages available, such as from a Satellite or another mirror, pass
`manage_repos=false`.  The plans then install packages with each host's package
manager from the repositories it already has.

The mirror needs:

* The OpenVox repository for the release you want (`openvox-agent`,
  `openvox-server`, `openvoxdb`, and `openvoxdb-termini`)
* If you install OpenVoxDB, the PostgreSQL server and contrib packages for
  `postgres_version`: from the PGDG repository (`postgresql17-server` and
  `postgresql17-contrib` by default), or, with `postgres_source=os`, from the
  operating system (`postgresql-server` and `postgresql-contrib`, from the
  AppStream `postgresql:16` module stream by default on EL 8 and 9)

`postgres_source=os` works whether or not `manage_repos` is set, since the
operating system's repositories are already configured.  OpenVoxDB needs
PostgreSQL 14 or later, so on EL 9 use the 15, 16, or 18 module stream (set
`postgres_version`) rather than the default PostgreSQL 13.  On EL 10, which has
no module streams, only its default `postgresql` packages (16) are supported.  Choose the source before OpenVoxDB is first installed:
switching later installs a second, empty PostgreSQL server rather than
migrating the data.

## Limitations

* The servers must be Linux hosts with systemd.  The agent targets must be
  Linux too, since `bootstrap::first_run` uses shell commands.
* The CA, OpenVoxDB, and compile master setup has only been tested on EL hosts.
* Standby CAs are copies of the active CA.  Don't point agents at a standby
  until you promote it, or the CAs' serial numbers will diverge.
