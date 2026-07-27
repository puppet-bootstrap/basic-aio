forge "https://forge.puppet.com/"

# stdlib is required by many other modules.
mod 'puppetlabs-stdlib', '9.7.0'

# puppetdb is needed in order to use exported resources.
mod 'puppetlabs-puppetdb', '8.1.0'

# These modules are all dependencies for puppetdb.
mod 'puppetlabs-inifile', '6.3.1'
mod 'puppetlabs-postgresql', '10.6.1'
mod 'puppetlabs-concat', '9.1.0'
mod 'puppetlabs-firewall', '8.3.0'

# r10k gives us dynamic Puppet environments.
mod 'puppet-r10k', '15.1.0'

# These modules are all dependencies for r10k.
mod 'puppetlabs-vcsrepo', '7.0.0' # Required by puppet-r10k
mod 'puppetlabs-git', '0.5.0' # Required by puppet-r10k

# Enables the EPEL repository on RHEL/CentOS.
mod 'puppet-epel', '6.0.0'

mod 'puppetlabs-puppetserver_gem', '1.1.1' # Required for eyaml.

# mcollective with NATS as message queue
mod 'choria-mcollective', '0.15.0'
mod 'choria-mcollective_agent_puppet', '2.5.0'
mod 'choria-mcollective_agent_package', '5.5.1'
mod 'choria-mcollective_agent_service', '4.1.0'
mod 'choria-mcollective_agent_filemgr', '2.1.0'
mod 'choria-mcollective_util_actionpolicy', '3.3.0'
mod 'choria-mcollective_choria', '0.22.2'
mod 'choria-choria', '0.31.0'

mod 'puppet-systemd', '9.4.0'
mod 'puppetlabs-apt', '11.2.0' # Required by puppetlabs-postgresql, choria-choria

# Manage firewalld
mod 'puppet-firewalld', '5.1.0'
