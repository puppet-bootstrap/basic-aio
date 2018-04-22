require 'spec_helper'

describe 'profile::agent' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      it { is_expected.to contain_class('profile::agent') }

      it {
        is_expected.to contain_service('puppet').with(
          'ensure' => 'running',
          'enable' => true,
        )
      }
    end
  end
end
