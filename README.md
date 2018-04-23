# basic-aio
## Bootstrap a basic Puppet environment using AIO packages

The master branch of this repo contains a Vagrantfile that will build a Puppet
server using the Puppet 5 all-in-one packages with the following configured
out of the box:
* [r10k](https://forge.puppet.com/puppet/r10k) (with this repo as its control repo)
* [Choria mcollective](http://choria.io/)
* [PuppetDB](https://puppet.com/docs/puppetdb/)
