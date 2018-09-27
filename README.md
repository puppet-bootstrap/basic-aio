# basic-aio
## Bootstrap a basic Puppet environment using AIO packages

The master branch of this repo contains a Vagrantfile that will build a Puppet
server using the Puppet 5 all-in-one packages with the following configured
out of the box:
* [r10k](https://forge.puppet.com/puppet/r10k) (with this repo as its control repo)
* [PuppetDB](https://puppet.com/docs/puppetdb/)

To get started with just an agent, take a look at
[sandbox](https://github.com/puppet-bootstrap/sandbox).  For a simple control
repo example, see
[minimal-control](https://github.com/puppet-bootstrap/minimal-control).
