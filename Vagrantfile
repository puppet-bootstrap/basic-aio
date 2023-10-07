# -*- mode: ruby -*-
# vi: set ft=ruby et st=2 sw=2 :
ENV['VAGRANT_EXPERIMENTAL'] = 'typed_triggers'

ip_subnet = ENV.fetch('IP_SUBNET', '192.168.32')
puppet_version = ENV.fetch('PUPPET_VERSION', '')
puppet_release = puppet_version.empty? ? ENV.fetch('PUPPET_RELEASE', '7') : puppet_version.split('.').first
el_release = ENV.fetch('EL_RELEASE', '9')
el_os_name = ENV.fetch('EL_OS_NAME', 'centos')
def select_box(el_os_name, el_release)
  return @box if @box

  @box = ENV['BOX']

  return @box unless @box.nil?

  @box = case el_os_name
         when 'centos'
           if el_release.to_i > 7
             "generic/#{el_os_name}#{el_release}s"
           else
             "generic/#{el_os_name}#{el_release}"
           end
         else
           "#{el_os_name}/#{el_release}"
         end
end
box = select_box(el_os_name, el_release)

Vagrant.configure('2') do |config|
  config.vm.box = box
  config.ssh.forward_agent = true

  config.vm.define 'puppet' do |puppetserver|
    puppetserver.vm.provider 'virtualbox' do |vb|
      vb.memory = '3072'
      vb.cpus = 2
      vb.name = 'puppet.vagrant'
    end

    puppetserver.vm.provider 'libvirt' do |libvirt|
      libvirt.memory = '3072'
      libvirt.cpus = 2
      libvirt.qemu_use_session = false
    end

    puppetserver.vm.hostname = 'puppet.vagrant'
    puppetserver.vm.network 'private_network', ip: "#{ip_subnet}.5"
    puppetserver.vm.synced_folder '.', '/vagrant'
  end

  config.vm.define 'agent' do |agent|
    agent.vm.provider 'virtualbox' do |vb|
      vb.name = 'agent.vagrant'
    end

    agent.vm.provider 'libvirt' do |libvirt|
      libvirt.qemu_use_session = false
    end

    agent.vm.hostname = 'agent.vagrant'
    agent.vm.network 'private_network', ip: "#{ip_subnet}.6"
  end

  config.trigger.before [:up, :provision, :reload], type: :command do |trigger|
    trigger.info = 'Initializing bolt'
    trigger.run = { inline: 'bolt module install' }
  end

  config.trigger.after [:up, :provision, :reload], type: :command do |trigger|
    trigger.info = 'Running bolt plan'
    trigger.run = {
      inline: [
        'bolt plan run role -t all --run-as root',
        "puppet_release=#{puppet_release}",
        "puppet_version=#{puppet_version}",
        '--stream',
        '--native-ssh',
      ].concat(ENV['DEBUG'].nil? ? [] : [
        '--verbose',
        '--trace',
        '--log-level debug',
      ]).join(' ')
    }
  end
end
