# -*- mode: ruby -*-
# vi: set ft=ruby et ts=2 sw=2 :
ENV['VAGRANT_EXPERIMENTAL'] = 'typed_triggers'

ip_subnet = ENV.fetch('IP_SUBNET', '192.168.32')
openvox_version = ENV.fetch('OPENVOX_VERSION', '')
openvox_release = openvox_version.empty? ? ENV.fetch('OPENVOX_RELEASE', '8') : openvox_version.split('.').first
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

def bolt_debug_options
  return [] if ENV['DEBUG'].nil?

  [
    '--verbose',
    '--trace',
    '--log-level debug',
  ]
end

require 'yaml'
stream = YAML.safe_load(ENV.fetch('VERBOSE', 'true'))
native_ssh = YAML.safe_load(ENV.fetch('NATIVE_SSH', 'true'))

Vagrant.configure('2') do |config|
  config.vm.box = box
  config.ssh.forward_agent = true

  config.vm.define 'puppet' do |server|
    server.vm.provider 'virtualbox' do |vb|
      vb.memory = '4096'
      vb.cpus = 2
      vb.name = 'puppet.vagrant'
    end

    server.vm.provider 'libvirt' do |libvirt|
      libvirt.memory = '4096'
      libvirt.cpus = 2
      libvirt.qemu_use_session = false
    end

    server.vm.hostname = 'puppet.vagrant'
    server.vm.network 'private_network', ip: "#{ip_subnet}.5"
    server.vm.synced_folder '.', '/vagrant',
      type: 'rsync',
      rsync__exclude: ['spec/fixtures/modules/']
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
    agent.vm.synced_folder '.', '/vagrant', disabled: true
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
        "openvox_release=#{openvox_release}",
        "openvox_version=#{openvox_version}",
      ].concat(bolt_debug_options)
       .concat(stream ? ['--stream'] : [])
       .concat(native_ssh ? ['--native-ssh'] : [])
       .join(' ')
    }
  end
end
