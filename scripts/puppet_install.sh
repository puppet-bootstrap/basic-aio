#!/bin/bash

rpm -ihv http://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm

yum -y install puppetserver puppet-agent
