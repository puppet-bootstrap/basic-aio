# -*- mode: ruby -*-
# vi: set ft=ruby et ts=2 sw=2 :
ENV['VAGRANT_EXPERIMENTAL'] = 'typed_triggers'

ip_subnet = ENV.fetch('IP_SUBNET', '192.168.32')
openvox_version = ENV.fetch('OPENVOX_VERSION', '')
openvox_release = openvox_version.empty? ? ENV.fetch('OPENVOX_RELEASE', '9') : openvox_version.split('.').first
el_release = ENV.fetch('EL_RELEASE', '9')
el_os_name = ENV.fetch('EL_OS_NAME', 'centos')
compilers = Integer(ENV.fetch('COMPILERS', '1'))
ca_servers = Integer(ENV.fetch('CA_SERVERS', '0'))
db_servers = Integer(ENV.fetch('DB_SERVERS', '0'))
db_password = ENV.fetch('DB_PASSWORD', 'puppetdb')
raise 'COMPILERS must be between 1 and 9' unless (1..9).cover?(compilers)
raise 'CA_SERVERS must be between 0 and 9' unless (0..9).cover?(ca_servers)
raise 'DB_SERVERS must be between 0 and 9' unless (0..9).cover?(db_servers)

# The first compile master is always `puppet`.  The CA and OpenVoxDB run on it
# unless CA_SERVERS or DB_SERVERS is set.
compiler_names = ['puppet'] + (2..compilers).map { |n| "compile#{n}" }
ca_names = (1..ca_servers).map { |n| "ca#{n}" }
db_names = (1..db_servers).map { |n| "db#{n}" }
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

  # name => [IP address suffix, memory in MB, sync /vagrant for r10k]
  machines = {}
  compiler_names.each_with_index do |name, i|
    machines[name] = [i.zero? ? 5 : 10 + i + 1, i.zero? ? 4096 : 3072, true]
  end
  ca_names.each_with_index { |name, i| machines[name] = [21 + i, 3072, false] }
  db_names.each_with_index { |name, i| machines[name] = [31 + i, 2048, false] }
  machines['agent'] = [6, 1024, false]

  machines.each do |name, (ip, memory, sync)|
    config.vm.define name do |node|
      node.vm.provider 'virtualbox' do |vb|
        vb.memory = memory.to_s
        vb.cpus = 2
        vb.name = "#{name}.vagrant"
      end

      node.vm.provider 'libvirt' do |libvirt|
        libvirt.memory = memory
        libvirt.cpus = 2
        libvirt.qemu_use_session = false
      end

      node.vm.hostname = "#{name}.vagrant"
      node.vm.network 'private_network', ip: "#{ip_subnet}.#{ip}"
      if sync
        node.vm.synced_folder '.', '/vagrant',
          type: 'rsync',
          rsync__exclude: ['spec/fixtures/modules/']
      else
        node.vm.synced_folder '.', '/vagrant', disabled: true
      end
    end
  end

  config.trigger.before [:up, :provision, :reload], type: :command do |trigger|
    trigger.info = 'Initializing bolt'
    trigger.run = { inline: 'bolt module install' }
  end

  config.trigger.after [:up, :provision, :reload], type: :command do |trigger|
    trigger.info = 'Running bolt plan'
    trigger.run = {
      inline: [
        'bolt plan run basic_aio -t all --run-as root',
        'server_target=puppet',
        "db_targets=#{(db_names.empty? ? ['puppet'] : db_names).join(',')}",
        "db_password=#{db_password}",
        'control_repo=file:///vagrant/',
        'manage_hosts=true',
        'manage_topology_data=true',
        %q('autosign=["*.vagrant","vagrant.mcollective"]'),
        'choria_user=vagrant',
        "openvox_release=#{openvox_release}",
        "openvox_version=#{openvox_version}",
      ].concat(compiler_names.length > 1 ? ["compilers=#{compiler_names.drop(1).join(',')}"] : [])
       .concat(ca_names.empty? ? [] : ["ca_targets=#{ca_names.join(',')}"])
       .concat(bolt_debug_options)
       .concat(stream ? ['--stream'] : [])
       .concat(native_ssh ? ['--native-ssh'] : [])
       .join(' ')
    }
  end
end
