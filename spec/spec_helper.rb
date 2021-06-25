require 'serverspec'
require 'net/ssh'
require 'tempfile'

set :backend, :ssh

if ENV['ASK_SUDO_PASSWORD']
  begin
    require 'highline/import'
  rescue LoadError
    fail "highline is not available. Try installing it."
  end
  set :sudo_password, ask("Enter sudo password: ") { |q| q.echo = false }
else
  set :sudo_password, ENV['SUDO_PASSWORD']
end

host = ENV['TARGET_HOST']

begin
  state = `vagrant status #{host} --machine-readable`.lines.map do |line|
    s = line.chomp.split(',')
    next if s[2] != 'state'
    [s[1], [s[2..-1]].to_h]
  end.delete_if { |i| i.nil? }.to_h
  if (host.nil? ? state.any { |k,v| v['state'] != 'running' } : (state[host]['state'] != 'running'))
    system("vagrant up #{host}")
  end
rescue => e
  warn "Failed to ensure running state: #{e.message}"
end

config = Tempfile.new('', Dir.tmpdir)
config.write(`vagrant ssh-config #{host}`)
config.close

options = Net::SSH::Config.for(host, [config.path])

options[:user] ||= Etc.getlogin

set :host,        options[:host_name] || host
set :ssh_options, options

# Disable sudo
# set :disable_sudo, true


# Set environment variables
# set :env, :LANG => 'C', :LC_MESSAGES => 'C'

# Set PATH
# set :path, '/sbin:/usr/local/sbin:$PATH'
