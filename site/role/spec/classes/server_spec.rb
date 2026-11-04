require 'spec_helper'

describe 'role::server' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts.merge(
          'puppet_environmentpath'    => '/etc/puppetlabs/code/environments',
          'puppet_vardir'             => '/opt/puppetlabs/puppet/cache',
          'role__server__r10k_remote' => 'file:///example',
        )
      end

      context 'on the all-in-one server' do
        let(:node) { 'puppet.vagrant' }

        it { is_expected.to compile }

        it { is_expected.to contain_class('role::server') }

        it { is_expected.to contain_class('r10k') }
        it { is_expected.to contain_class('profile::server') }
        it { is_expected.to contain_class('profile::ca') }
        it { is_expected.to contain_class('profile::db') }
        it { is_expected.to contain_class('openvoxdb') }
        it { is_expected.to contain_class('bootstrap::server::puppetdb') }
        it { is_expected.to contain_class('choria').with('manage_package_repo' => true) }
        it { is_expected.to contain_class('choria::broker').with('network_broker' => true) }
      end

      context 'with a split infrastructure' do
        let(:pre_condition) do
          <<~PP
            class { 'profile::topology':
              primary    => 'puppet.vagrant',
              server     => 'puppet.vagrant',
              compilers  => ['puppet.vagrant', 'compile2.vagrant'],
              ca_servers => ['ca1.vagrant'],
              db_servers => ['db1.vagrant'],
            }
          PP
        end

        context 'on a compile master' do
          let(:node) { 'compile2.vagrant' }

          it { is_expected.to compile }
          it { is_expected.to contain_class('profile::server') }
          it { is_expected.to contain_class('r10k') }
          it { is_expected.not_to contain_class('profile::ca') }
          it { is_expected.not_to contain_class('profile::db') }
          it { is_expected.not_to contain_class('choria::broker') }
        end

        context 'on the CA' do
          let(:node) { 'ca1.vagrant' }

          it { is_expected.to compile }
          it { is_expected.to contain_class('profile::server') }
          it { is_expected.to contain_class('profile::ca') }
          it { is_expected.not_to contain_class('r10k') }
          it { is_expected.not_to contain_class('profile::db') }
        end

        context 'on the OpenVoxDB host' do
          let(:node) { 'db1.vagrant' }

          it { is_expected.to compile }
          it { is_expected.to contain_class('profile::db') }
          it { is_expected.not_to contain_class('profile::server') }
          it { is_expected.not_to contain_class('r10k') }
        end
      end
    end
  end
end
