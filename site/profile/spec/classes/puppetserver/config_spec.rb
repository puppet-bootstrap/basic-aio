require 'spec_helper'

describe 'profile::puppetserver::config' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          'autosign' => [
            '*.test',
            '*.rspec',
          ],
        }
      end

      it { is_expected.to compile }

      it { is_expected.to contain_class('profile::puppetserver::config') }

      it {
        is_expected.to contain_file('/etc/puppetlabs/puppet/autosign.conf').with(
          'ensure' => 'file',
          'owner'  => 'root',
          'group'  => 'root',
          'mode'   => '0644',
        ).with_content(%r{^\*\.test$}).with_content(%r{^\*\.rspec$})
      }
    end
  end
end
