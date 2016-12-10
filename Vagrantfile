# -*- mode: ruby -*-
# vi: set ft=ruby et st=2 sw=2 :

Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"

  config.vm.define :puppetmaster do |puppetmaster|
    puppetmaster.vm.provider :virtualbox do |vb|
      vb.memory = "2048"
      vb.name = "puppetmaster.vagrant"
      vb.cpus = 2
    end

    puppetmaster.vm.provider :libvirt do |libvirt|
      libvirt.memory = "2048"
      libvirt.cpus = 2
    end


    puppetmaster.vm.provision :shell, :path => 'scripts/common.sh'
    puppetmaster.vm.provision :shell, :path => 'scripts/puppet_install.sh'
  end
end
