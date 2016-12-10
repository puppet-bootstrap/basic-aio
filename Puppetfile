forge "https://forge.puppetlabs.com/"

# stdlib is required by many other modules.
mod 'puppetlabs/stdlib','4.13.1'

# puppetdb is needed in order to use exported resources.
mod 'puppetlabs/puppetdb','5.1.2'

# These modules are all dependencies for puppetdb.
mod 'puppetlabs/inifile','1.6.0'
mod 'puppetlabs/postgresql','4.8.0'
mod 'puppetlabs/apt','2.3.0'
mod 'puppetlabs/concat','2.2.0'
mod 'puppetlabs/firewall','1.8.1'

# r10k gives us dynamic Puppet environments.
mod 'puppet/r10k','4.0.2'

# These modules are all dependencies for r10k.
mod 'puppetlabs/ruby','0.5.0'
mod 'puppetlabs/gcc','0.3.0'
mod 'puppetlabs/pe_gem','0.2.0'
mod 'puppet/make','1.0.1' # Replaces croddy/make
#mod 'puppetlabs/inifile','1.6.0' # Already listed above.
mod 'puppetlabs/vcsrepo','1.4.0'
mod 'puppetlabs/git','0.5.0'
mod 'gentoo/portage','2.3.0'

# Enables the EPEL repository on RHEL/CentOS.
mod 'stahnma/epel','1.2.2'

# Configures hiera.
mod 'puppet/hiera','2.3.0'

# These modules are dependencies for hiera.
#mod 'puppetlabs/inifile','1.6.0' # Already listed above.
mod 'puppetlabs/puppetserver_gem','0.2.0' # Required for eyaml.
