forge "https://forge.puppet.com/"

# stdlib is required by many other modules.
mod 'puppetlabs-stdlib', '6.3.0'

# Manages the puppetserver package and service.
mod 'puppet-puppetserver', '3.0.1'

# puppetdb is needed in order to use exported resources.
mod 'puppetlabs-puppetdb', '7.5.0'

# These modules are all dependencies for puppetdb.
mod 'puppetlabs-inifile', '4.2.0'
mod 'puppetlabs-postgresql', '6.5.0'
mod 'puppetlabs-apt', '7.4.2'
mod 'puppetlabs-concat', '6.2.0'
mod 'puppetlabs-firewall', '2.4.0'

# r10k gives us dynamic Puppet environments.
mod 'puppet-r10k', '8.3.0'

# These modules are all dependencies for r10k.
mod 'puppetlabs-ruby', '1.0.1' # Required by puppet-r10k
mod 'puppetlabs-vcsrepo', '3.1.0' # Required by puppet-r10k
mod 'puppetlabs-git', '0.5.0' # Required by puppet-r10k

# Enables the EPEL repository on RHEL/CentOS.
mod 'puppet-epel', '3.0.1'

mod 'puppetlabs-puppetserver_gem', '1.1.1' # Required for eyaml.
mod 'puppetlabs-translate', '2.2.0' # Required by puppetlabs-apt
mod 'herculesteam-augeasproviders_core', '2.6.0' # Required by puppet-puppetserver
mod 'camptocamp-augeas', '1.9.0' # Required by puppet-puppetserver

# mcollective with NATS as message queue
mod 'choria-mcollective', '0.10.4'
mod 'choria-mcollective_agent_puppet', '2.3.2'
mod 'choria-mcollective_agent_package', '5.2.0'
mod 'choria-mcollective_agent_service', '4.0.1'
mod 'choria-mcollective_agent_filemgr', '2.0.1'
mod 'choria-mcollective_util_actionpolicy', '3.2.0'
mod 'choria-mcollective_choria', '0.17.2'
mod 'choria-choria', '0.16.0'

mod 'camptocamp-systemd', '2.9.0'
mod 'puppetlabs-augeas_core', '1.0.5' # Required by puppet-puppetserver, camptocamp-augeas
