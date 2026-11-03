# bootstrap

[OpenBolt](https://github.com/OpenVoxProject/openbolt) plans to stand up an
OpenVox server and agents on existing hosts.

The plans use the tasks in
[puppet/openvox_bootstrap](https://github.com/voxpupuli/puppet-openvox_bootstrap)
to install packages and configure the agent, and only core resource types
otherwise, so they don't depend on any particular control repo.

## Plans

* `bootstrap`: runs the three plans below in order.
* `bootstrap::install_agents`: installs openvox-agent, collects facts, and sets
  `server` in `puppet.conf`.  The puppet service is left stopped.
* `bootstrap::install_server`: installs openvox-server, optionally sets
  `dns_alt_names`, autosigning, and the firewalld `puppetmaster` service, and
  starts puppetserver.
* `bootstrap::first_run`: runs the agent on the server, then on the other
  targets.  For agents whose first run fails because their certificate isn't
  signed yet, it signs their certificate requests on the server and runs them
  again.  Then it starts the puppet service.

If you need to do something between those steps, such as deploying code to
the server, call the individual plans yourself.  This repo's `basic_aio` plan
does that to set up r10k before the server's first agent run.

See [REFERENCE.md](REFERENCE.md) for parameters.

## Example

```sh
bolt plan run bootstrap \
  --targets server.example.com,agent1.example.com,agent2.example.com \
  server_target=server.example.com \
  openvox_release=9 \
  manage_firewall=true \
  --run-as root
```

## Limitations

* The server must be a Linux host with systemd.  The agent targets must be
  Linux too, since `bootstrap::first_run` uses shell commands.
* The server is also the CA.
