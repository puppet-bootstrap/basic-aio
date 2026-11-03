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
targets; the server must use systemd.

The portable parts live in the `bootstrap` module in `site/bootstrap`, which
you can also use on its own.  See its [README](site/bootstrap/README.md).

## See also

To get started with just an agent, take a look at
[sandbox](https://github.com/puppet-bootstrap/sandbox).  For a simple control
repo example, see
[minimal-control](https://github.com/puppet-bootstrap/minimal-control).
