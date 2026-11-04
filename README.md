# basic-aio
## Bootstrap a basic OpenVox environment

The production branch of this repo contains a Vagrantfile that will build an OpenVox
server and agent with the following configured out of the box:

* [r10k](https://forge.puppet.com/puppet/r10k) (with this repo as its control repo)
* [Choria mcollective](http://choria.io/)
* [openvoxdb](https://puppet.com/docs/puppetdb/)

## Prerequisites

In order to use this project, you'll need
[OpenBolt](https://github.com/OpenVoxProject/openbolt) installed.  For the
demo environment, you'll also need [Vagrant](https://vagrantup.com/).

### Configuring basic-aio

The following environment variables are used to configure the Vagrant environment:

| Environment variable | Default value          | Description                                          |
| -------------------- | -------------          | -----------                                          |
| `IP_SUBNET`          | `192.168.32`           | The internal IP subnet used by Vagrant               |
| `OPENVOX_VERSION`    | none (use the latest)  | The OpenVox agent version                            |
| `OPENVOX_RELEASE`    | `9`                    | The OpenVox major release version                    |
| `EL_RELEASE`         | `9`                    | The EL release of the base box                       |
| `EL_OS_NAME`         | `centos`               | The base box OS                                      |
| `BOX`                | Depends on EL_OS_NAME  | The base box name                                    |
| `DEBUG`              | not set                | Set to enable debugging output                       |
| `VERBOSE`            | `true`                 | Set to `false` to disable verbose (streaming) output |
| `NATIVE_SSH`         | `true`                 | Set to `false` to disable native SSH                 |
| `COMPILERS`          | `1`                    | The number of compile masters (1-9)                  |
| `CA_SERVERS`         | `0`                    | The number of standalone CA servers (0-9)            |
| `DB_SERVERS`         | `0`                    | The number of standalone OpenVoxDB servers (0-9)     |
| `DB_PASSWORD`        | `puppetdb`             | The OpenVoxDB PostgreSQL password                    |
| `POSTGRES_SOURCE`    | `pgdg`                 | Where PostgreSQL comes from (`pgdg` or `os`)         |

### Splitting up the infrastructure

By default, `puppet.vagrant` is the only compile master, and it also runs the
CA and OpenVoxDB.  The `COMPILERS`, `CA_SERVERS`, and `DB_SERVERS` variables
add more hosts:

| Hosts                         | Role                                                              |
| -----                         | ----                                                              |
| `puppet.vagrant`              | The primary compile master (and the CA and OpenVoxDB by default)  |
| `compile2.vagrant`, ...       | Additional compile masters, with the CA service disabled          |
| `ca1.vagrant`, `ca2.vagrant`, ... | The active CA (`ca1`) and standby CAs with a copy of its CA directory |
| `db1.vagrant`, `db2.vagrant`, ... | OpenVoxDB.  `db1` also runs PostgreSQL for the others.        |

For example, this builds two compile masters, an active and a standby CA, and
two OpenVoxDB hosts (plus the agent):

```sh
COMPILERS=2 CA_SERVERS=2 DB_SERVERS=2 vagrant up
```

Agents use `puppet.vagrant` as their server.  Every compile master gets the
code from `/vagrant` with r10k and connects to every OpenVoxDB host.  To switch
to a standby CA, set `ca_server` to it on every host; until then, rerun the
`bootstrap::sync_ca` plan to copy newly signed certificates to the standbys.

## Bootstrapping your own nodes

The `Boltdir` in this repo is an OpenBolt project, and `vagrant up` just runs
its `basic_aio` plan.  You can run the same plan against your own hosts to
install an OpenVox server and agents, and optionally deploy your own control
repo to the server with r10k before the first agent run:

```sh
cd Boltdir
bolt module install
bolt plan run basic_aio \
  --targets server.example.com,agent1.example.com,agent2.example.com \
  --run-as root \
  server_target=server.example.com \
  openvox_release=9 \
  control_repo=https://github.com/example/control-repo.git
```

Agents whose certificates aren't autosigned are signed by the plan after their
first run.  Run `bolt plan show basic_aio` for all of the options, such as
`autosign`, `dns_alt_names`, and `openvox_version`.  The plan works on Linux
targets, and the servers must use systemd.  The CA, OpenVoxDB, and compile master
setup has only been tested on EL hosts.

To put the CA, OpenVoxDB, or more compile masters on their own hosts, add
`ca_targets`, `db_targets` (with `db_password`), and `compilers`:

```sh
bolt plan run basic_aio \
  --targets agent1.example.com,agent2.example.com \
  --run-as root \
  server_target=primary.example.com \
  compilers=compile2.example.com,compile3.example.com \
  ca_targets=ca1.example.com,ca2.example.com \
  db_targets=db1.example.com \
  db_password="$OPENVOXDB_PASSWORD" \
  dns_alt_names='["puppet.example.com"]' \
  openvox_server=puppet.example.com \
  control_repo=https://github.com/example/control-repo.git
```

On hosts that can't reach the internet but already have the OpenVox (and, for
OpenVoxDB, PostgreSQL) packages available, such as from a Satellite, add
`manage_repos=false`.  Add `postgres_source=os` to use the operating system's
PostgreSQL packages (on EL 8 and 9, the AppStream `postgresql:16` module
stream) instead of PGDG's.  See the `bootstrap` module's
[README](site/bootstrap/README.md#airgapped-hosts) for what the mirror needs.
`control_repo` also needs internet access unless you plan for it: r10k installs
itself from rubygems.org, and deploys any Forge modules in the control repo's
`Puppetfile` from forge.puppet.com.

Each host's certname is the FQDN from its facts.  Decide on a load balancer
name for the compile masters before the first run, and put it in
`dns_alt_names` (and `openvox_server`), since alternate names only apply when
a certificate is first issued.  `alias_server_names=true` adds those names to
every target's hosts file as aliases of `server_target`.  When adding compile
masters later, rerun the plan with the complete list: the OpenVoxDB
certificate allowlist is rebuilt from it.

The portable parts live in the `bootstrap` module in `site/bootstrap`, which
you can also use on its own.  See its [README](site/bootstrap/README.md).

## See also

To get started with just an agent, take a look at
[sandbox](https://github.com/puppet-bootstrap/sandbox).  For a simple control
repo example, see
[minimal-control](https://github.com/puppet-bootstrap/minimal-control).
