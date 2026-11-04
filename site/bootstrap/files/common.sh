# shellcheck shell=bash
# Shared helpers for the bootstrap module's shell tasks.
#
# Tasks load this file with:
#   . "${PT__installdir}/bootstrap/files/common.sh"

set -euo pipefail

export PATH="/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:/usr/sbin:/usr/bin:/sbin:/bin"

log() {
  echo "[$(hostname -s)] $*"
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

require_root() {
  [ "$(id -u)" -eq 0 ] || fail "This task must run as root (use --run-as root)."
}

# puppet_set SECTION SETTING VALUE
puppet_set() {
  local section="$1" setting="$2" value="$3" current
  current="$(puppet config print "$setting" --section "$section" 2>/dev/null || true)"
  if [ "$current" != "$value" ]; then
    log "puppet.conf [${section}] ${setting} = ${value}"
    puppet config set "$setting" "$value" --section "$section"
  fi
}

# JSON array (from a Bolt Array parameter) -> one value per line.
json_list() {
  /opt/puppetlabs/puppet/bin/ruby -rjson -e 'JSON.parse(ARGV[0] || "[]").each { |v| puts v }' "${1:-[]}"
}
