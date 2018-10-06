# -*- mode: ruby -*-
# vi: set ft=ruby et st=2 sw=2 :

puppetagent = <<SCRIPT
# If puppet successfully applied changes, it returns 2.
# Vagrant sees a non-zero return code as a failure. If puppet returns 2,
# return a zero so vagrant doesn't report an error
puppet agent -t -w 30 || { [ $? -eq 2 ] && true; };
SCRIPT

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
    puppetmaster.vm.provision :shell, :inline => puppetagent
  end

  config.vm.define :agent do |agent|
    agent.vm.provider :virtualbox do |vb|
      vb.name = 'agent.vagrant'
    end

    agent.vm.hostname = 'agent.vagrant'
    agent.vm.network :private_network, ip: '192.168.32.6'

    agent.vm.provision :shell, :path => 'scripts/common.sh'
    agent.vm.provision :shell, :inline => puppetagent
  end
end
