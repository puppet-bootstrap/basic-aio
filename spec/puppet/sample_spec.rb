require 'spec_helper'

describe package('puppetserver'), :if => os[:family] == 'redhat' do
    it { should be_installed }
end

describe port(8140) do
    it { should be_listening }
end

describe service ('puppetserver'), :if => os[:family] == 'redhat' do
    it { should be_enabled }
    it { should be_running }
end

describe package('httpd'), :if => os[:family] == 'redhat' do
  it { should_not be_installed }
end

describe package('apache2'), :if => os[:family] == 'ubuntu' do
  it { should_not be_installed }
end

describe service('httpd'), :if => os[:family] == 'redhat' do
  it { should_not be_enabled }
  it { should_not be_running }
end

describe service('apache2'), :if => os[:family] == 'ubuntu' do
  it { should_not be_enabled }
  it { should_not be_running }
end

describe service('org.apache.httpd'), :if => os[:family] == 'darwin' do
  it { should_not be_enabled }
  it { should_not be_running }
end

describe port(80) do
  it { should_not be_listening }
end
