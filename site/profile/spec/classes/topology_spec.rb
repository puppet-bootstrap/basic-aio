# frozen_string_literal: true

require 'spec_helper'

describe 'profile::topology' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:node) { 'compile2.vagrant' }
      let(:params) do
        {
          primary: 'puppet.vagrant',
          server: 'puppet.vagrant',
          compilers: ['puppet.vagrant', 'compile2.vagrant'],
          ca_servers: ['ca1.vagrant', 'ca2.vagrant'],
          db_servers: ['db1.vagrant', 'db2.vagrant'],
        }
      end

      it { is_expected.to compile }
    end
  end
end
