forge "https://forge.puppet.com/"

# stdlib is required by many other modules.
mod 'puppetlabs-stdlib', '9.4.0'

# puppetdb is needed in order to use exported resources.
mod 'puppetlabs-puppetdb', '7.13.0'

# These modules are all dependencies for puppetdb.
mod 'puppetlabs-inifile', '6.1.0'
mod 'puppetlabs-postgresql', '9.2.0'
mod 'puppetlabs-concat', '9.0.0'
mod 'puppetlabs-firewall', '7.0.2'

# r10k gives us dynamic Puppet environments.
mod 'puppet-r10k', '12.2.0'

# These modules are all dependencies for r10k.
mod 'puppetlabs-vcsrepo', '6.1.0' # Required by puppet-r10k
mod 'puppetlabs-git', '0.5.0' # Required by puppet-r10k

# Enables the EPEL repository on RHEL/CentOS.
mod 'puppet-epel', '5.0.0'

mod 'puppetlabs-puppetserver_gem', '1.1.1' # Required for eyaml.

# mcollective with NATS as message queue
mod 'choria-mcollective', '0.14.4'
mod 'choria-mcollective_agent_puppet', '2.4.2'
mod 'choria-mcollective_agent_package', '5.4.0'
mod 'choria-mcollective_agent_service', '4.0.1'
mod 'choria-mcollective_agent_filemgr', '2.0.1'
mod 'choria-mcollective_util_actionpolicy', '3.2.0'
mod 'choria-mcollective_choria', '0.22.0'
mod 'choria-choria', '0.30.1'

mod 'puppet-systemd', '6.0.0'
mod 'puppetlabs-apt', '9.1.0' # Required by puppetlabs-postgresql, choria-choria

# Manage firewalld
mod 'puppet-firewalld', '4.5.1'
