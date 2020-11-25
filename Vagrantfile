# -*- mode: ruby -*-
# vi: set ft=ruby et st=2 sw=2 :

ip_subnet = ENV['IP_SUBNET'] || '192.168.32'
puppet_version = ENV['PUPPET_VERSION'] || ''
puppet_release = puppet_version.empty? ? (ENV['PUPPET_RELEASE'] || '6') : puppet_version.split('.').first
el_release = ENV['EL_RELEASE'] || '7'
box = ENV['BOX'] || "centos/#{el_release}"

puppetagent = <<SCRIPT
delay=30
until ( : > /dev/tcp/puppet/8140 ) 2>/dev/null ; do
  echo "Waiting for puppet server..." >&2
  sleep $delay
done
# If puppet successfully applied changes, it returns 2.
# Vagrant sees a non-zero return code as a failure. If puppet returns 2,
# return a zero so vagrant doesn't report an error
puppet agent -t -w $delay || { [ $? -eq 2 ] && true; };
SCRIPT

Vagrant.configure('2') do |config|
  config.vm.box = box

  config.vm.define 'puppet' do |puppetmaster|
    puppetmaster.vm.provider 'virtualbox' do |vb|
      vb.memory = '3072'
      vb.cpus = 2
      vb.name = 'puppet.vagrant'
      # vb.customize ['modifyvm', :id, '--name', 'puppet.vagrant']
    end

    puppetmaster.vm.provider 'libvirt' do |libvirt|
      libvirt.memory = '3072'
      libvirt.cpus = 2
      libvirt.qemu_use_session = false
    end

    puppetmaster.vm.hostname = 'puppet.vagrant'
    puppetmaster.vm.network 'private_network', ip: "#{ip_subnet}.5"

    puppetmaster.vm.provision 'shell',
      path: 'scripts/common.sh',
      args: [puppet_release, el_release, ip_subnet, puppet_version]
    puppetmaster.vm.provision 'shell', path: 'scripts/puppet_install.sh'
    puppetmaster.vm.provision 'shell', inline: puppetagent
    puppetmaster.vm.provision 'shell',
      inline: "su -- vagrant -c 'mco choria request_cert'"
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

    agent.vm.provision 'shell',
      path: 'scripts/common.sh',
      args: [puppet_release, el_release, ip_subnet, puppet_version]
    agent.vm.provision 'shell', inline: puppetagent
  end
end
