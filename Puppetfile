forge "https://forge.puppet.com/"

# stdlib is required by many other modules.
mod 'puppetlabs-stdlib', '7.1.0'

# puppetdb is needed in order to use exported resources.
mod 'puppetlabs-puppetdb', '7.9.0'

# These modules are all dependencies for puppetdb.
mod 'puppetlabs-inifile', '5.1.0'
mod 'puppetlabs-postgresql', '7.2.0'
mod 'puppetlabs-concat', '7.0.2'
mod 'puppetlabs-firewall', '3.0.1'

# r10k gives us dynamic Puppet environments.
mod 'puppet-r10k', '10.0.0'

# These modules are all dependencies for r10k.
mod 'puppetlabs-ruby', '1.0.1' # Required by puppet-r10k
mod 'puppetlabs-vcsrepo', '5.0.0' # Required by puppet-r10k
mod 'puppetlabs-git', '0.5.0' # Required by puppet-r10k

# Enables the EPEL repository on RHEL/CentOS.
mod 'puppet-epel', '3.0.1'

mod 'puppetlabs-puppetserver_gem', '1.1.1' # Required for eyaml.
mod 'puppetlabs-translate', '2.2.0' # Required by puppetlabs-apt

# mcollective with NATS as message queue
mod 'choria-mcollective', '0.13.2'
mod 'choria-mcollective_agent_puppet', '2.4.1'
mod 'choria-mcollective_agent_package', '5.3.0'
mod 'choria-mcollective_agent_service', '4.0.1'
mod 'choria-mcollective_agent_filemgr', '2.0.1'
mod 'choria-mcollective_util_actionpolicy', '3.2.0'
mod 'choria-mcollective_choria', '0.21.0'
mod 'choria-choria', '0.24.0'

mod 'camptocamp-systemd', '3.0.0'
