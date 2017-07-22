forge "https://forge.puppetlabs.com/"

# stdlib is required by many other modules.
mod 'puppetlabs/stdlib','4.17.1'

# puppetdb is needed in order to use exported resources.
mod 'puppetlabs/puppetdb','6.0.1'

# These modules are all dependencies for puppetdb.
mod 'puppetlabs/inifile','1.6.0'
mod 'puppetlabs/postgresql','5.1.0'
mod 'puppetlabs/apt','4.1.0'
mod 'puppetlabs/concat','4.0.1'
mod 'puppetlabs/firewall','1.9.0'

# r10k gives us dynamic Puppet environments.
mod 'puppet/r10k','6.1.0'

# These modules are all dependencies for r10k.
mod 'puppetlabs/ruby','1.0.0'
mod 'puppetlabs/gcc','0.3.0'
#mod 'puppetlabs/pe_gem','0.2.0'
mod 'puppet/make','1.1.0' # Replaces croddy/make
#mod 'puppetlabs/inifile','1.6.0' # Already listed above.
mod 'puppetlabs/vcsrepo','2.0.0'
mod 'puppetlabs/git','0.5.0'
mod 'gentoo/portage','2.3.0'

# Enables the EPEL repository on RHEL/CentOS.
mod 'stahnma/epel','1.2.2'

# Configures hiera.
mod 'puppet/hiera','3.0.0'

# These modules are dependencies for hiera.
#mod 'puppetlabs/inifile','1.6.0' # Already listed above.
mod 'puppetlabs/puppetserver_gem','1.0.0' # Required for eyaml.

# mcollective with NATS as message queue
mod 'choria/mcollective','0.0.27'
#mod 'puppetlabs/inifile','1.6.0' # Already listed above.
mod 'choria/mcollective_agent_puppet','1.13.1'
mod 'choria/mcollective_agent_package','4.5.0'
mod 'choria/mcollective_agent_service','3.1.5'
mod 'choria/mcollective_agent_filemgr','1.1.0'
mod 'choria/mcollective_util_actionpolicy','2.2.0'
mod 'choria/mcollective_choria','0.0.27'
mod 'choria/nats','0.0.11'
mod 'camptocamp/systemd','0.4.0'

