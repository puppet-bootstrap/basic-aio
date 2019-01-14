forge "https://forge.puppetlabs.com/"

# stdlib is required by many other modules.
mod 'puppetlabs/stdlib','5.1.0'

# Manages the puppetserver package and service.
mod 'puppet/puppetserver','3.0.1'

# puppetdb is needed in order to use exported resources.
mod 'puppetlabs/puppetdb','7.1.0'

# These modules are all dependencies for puppetdb.
mod 'puppetlabs/inifile','2.5.0'
mod 'puppetlabs/postgresql','5.11.0'
mod 'puppetlabs/apt','6.2.1'
mod 'puppetlabs/concat','5.2.0'
mod 'puppetlabs/firewall','1.14.0'

# r10k gives us dynamic Puppet environments.
mod 'puppet/r10k','6.8.0'

# These modules are all dependencies for r10k.
mod 'puppetlabs/ruby','1.0.0'
mod 'puppetlabs/gcc','0.3.0'
#mod 'puppetlabs/pe_gem','0.2.0'
mod 'puppet/make','2.1.1'
#mod 'puppetlabs/inifile','1.6.0' # Already listed above.
mod 'puppetlabs/vcsrepo','2.4.0'
mod 'puppetlabs/git','0.5.0'
mod 'gentoo/portage','2.3.0'

# Enables the EPEL repository on RHEL/CentOS.
mod 'stahnma/epel','1.3.1'

mod 'puppetlabs/puppetserver_gem','1.1.0' # Required for eyaml.
mod 'puppetlabs-translate', '1.2.0' # Required by puppetlabs-apt
mod 'herculesteam-augeasproviders_core', '2.2.0' # Required by puppet-puppetserver
mod 'camptocamp-augeas', '1.7.0' # Required by puppet-puppetserver

# mcollective with NATS as message queue
mod 'choria/mcollective','0.9.0'
mod 'choria/mcollective_agent_puppet','2.3.1'
mod 'choria/mcollective_agent_package','5.1.0'
mod 'choria/mcollective_agent_service','4.0.1'
mod 'choria/mcollective_agent_filemgr','2.0.1'
mod 'choria/mcollective_util_actionpolicy','3.0.0'
mod 'choria/mcollective_choria','0.12.1'
mod 'choria/choria','0.12.0'
mod 'camptocamp/systemd','2.1.0'
