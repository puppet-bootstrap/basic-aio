# @summary Open TCP ports in firewalld, if firewalld is running
#
# @param targets The targets to open the ports on
# @param ports The TCP ports to open
plan bootstrap::open_ports (
  TargetSpec           $targets,
  Array[Integer[1], 1] $ports,
) {
  $add = $ports.map |$port| { "firewall-cmd -q --permanent --add-port=${port}/tcp" }.join(' && ')
  $query = $ports.map |$port| { "firewall-cmd -q --permanent --query-port=${port}/tcp" }.join(' && ')

  run_command(
    "if systemctl -q is-active firewalld ; then ${query} || { ${add} && firewall-cmd -q --reload ; } ; fi",
    $targets,
    "Opening ${ports.join(', ')}/tcp in firewalld",
  )
}
