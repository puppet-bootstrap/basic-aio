# -*- mode: ruby -*-
# vi: set ft=ruby et st=2 sw=2 :

Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"

  config.vm.define :puppet do |puppetmaster|
    puppetmaster.vm.provider :virtualbox do |vb|
      vb.memory = "3072"
      vb.cpus = 2
      vb.name = 'puppet.vagrant'
      #vb.customize ['modifyvm', :id, '--name', 'puppet.vagrant']
    end

    puppetmaster.vm.provider :libvirt do |libvirt|
      libvirt.memory = "3072"
      libvirt.cpus = 2
    end
    puppetmaster.vm.hostname = 'puppet.vagrant'
    puppetmaster.vm.network :private_network, ip: '192.168.32.5'

    puppetmaster.vm.provision :shell, :path => 'scripts/common.sh'
    puppetmaster.vm.provision :shell, :path => 'scripts/puppet_install.sh'
  end
end
