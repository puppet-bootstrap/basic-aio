# frozen_string_literal: true

require 'spec_helper'

describe 'profile::ca' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:node) { 'puppet.vagrant' }
      let(:pre_condition) { 'include profile::server' }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_class('bootstrap::ca').with_autosign(['*.vagrant', 'vagrant.mcollective']) }
      it { is_expected.to contain_file('/etc/puppetlabs/puppet/autosign.conf').with_content("*.vagrant\nvagrant.mcollective\n") }
    end
  end
end
