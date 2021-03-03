# -*- mode: ruby -*-
# vi: set ft=ruby et st=2 sw=2 :
ENV['VAGRANT_EXPERIMENTAL'] = 'typed_triggers'

ip_subnet = ENV['IP_SUBNET'] || '192.168.32'
puppet_version = ENV['PUPPET_VERSION'] || ''
puppet_release = puppet_version.empty? ? (ENV['PUPPET_RELEASE'] || '6') : puppet_version.split('.').first
el_release = ENV['EL_RELEASE'] || '7'
box = ENV['BOX'] || "centos/#{el_release}"

Vagrant.configure('2') do |config|
  config.vm.box = box

  config.vm.define 'puppet' do |puppetmaster|
    puppetmaster.vm.provider 'virtualbox' do |vb|
      vb.memory = '3072'
      vb.cpus = 2
      vb.name = 'puppet.vagrant'
    end

    puppetmaster.vm.provider 'libvirt' do |libvirt|
      libvirt.memory = '3072'
      libvirt.cpus = 2
      libvirt.qemu_use_session = false
    end

    puppetmaster.vm.hostname = 'puppet.vagrant'
    puppetmaster.vm.network 'private_network', ip: "#{ip_subnet}.5"
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
      ].join(' ')
    }
  end
end
