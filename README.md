# basic-aio
## Bootstrap a basic OpenVox environment

The production branch of this repo contains a Vagrantfile that will build an OpenVox
server and agent with the following configured out of the box:

* [r10k](https://forge.puppet.com/puppet/r10k) (with this repo as its control repo)
* [Choria mcollective](http://choria.io/)
* [openvoxdb](https://puppet.com/docs/puppetdb/)

## Prerequisites

In order to use this project, you'll need
[Vagrant](https://vagrantup.com/) and
[Bolt](https://puppet.com/docs/bolt/latest/bolt.html) installed.

### Configuring basic-aio

The following environment variables are used to configure the Vagrant environment:

| Environment variable | Default value          | Description                                          |
| -------------------- | -------------          | -----------                                          |
| `IP_SUBNET`          | `192.168.32`           | The internal IP subnet used by Vagrant               |
| `OPENVOX_VERSION`    | none (use the latest)  | The OpenVox agent version                            |
| `OPENVOX_RELEASE`    | `8`                    | The OpenVox major release version                    |
| `EL_RELEASE`         | `9`                    | The EL release of the base box                       |
| `EL_OS_NAME`         | `centos`               | The base box OS                                      |
| `BOX`                | Depends on EL_OS_NAME  | The base box name                                    |
| `DEBUG`              | not set                | Set to enable debugging output                       |
| `VERBOSE`            | `true`                 | Set to `false` to disable verbose (streaming) output |
| `NATIVE_SSH`         | `true`                 | Set to `false` to disable native SSH                 |

## See also

To get started with just an agent, take a look at
[sandbox](https://github.com/puppet-bootstrap/sandbox).  For a simple control
repo example, see
[minimal-control](https://github.com/puppet-bootstrap/minimal-control).
