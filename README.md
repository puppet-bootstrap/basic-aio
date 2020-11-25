# basic-aio
## Bootstrap a basic Puppet environment using AIO packages

The production branch of this repo contains a Vagrantfile that will build a Puppet
server using the Puppet all-in-one packages with the following configured
out of the box:
* [r10k](https://forge.puppet.com/puppet/r10k) (with this repo as its control repo)
* [Choria mcollective](http://choria.io/)
* [PuppetDB](https://puppet.com/docs/puppetdb/)

To get started with just an agent, take a look at
[sandbox](https://github.com/puppet-bootstrap/sandbox).  For a simple control
repo example, see
[minimal-control](https://github.com/puppet-bootstrap/minimal-control).

### Configuring basic-aio

The following environment variables are used to configure the Vagrant environment:

| Environment variable | Default value          | Description                            |
| -------------------- | -------------          | -----------                            |
| `IP_SUBNET`          | `192.168.32`           | The internal IP subnet used by Vagrant |
| `PUPPET_VERSION`     | none (use the latest)  | The Puppet agent version               |
| `PUPPET_RELEASE`     | `6`                    | The Puppet major release version       |
| `EL_RELEASE`         | `7`                    | The EL release of the base box         |
| `BOX`                | `centos/${EL_RELEASE}` | The base box name                      |
