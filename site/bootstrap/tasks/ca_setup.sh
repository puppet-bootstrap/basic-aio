#!/bin/bash
# shellcheck source=../files/common.sh
# shellcheck disable=SC2154
. "${PT__installdir}/bootstrap/files/common.sh"

require_root

certname="${PT_certname:?certname is required}"
command -v puppetserver >/dev/null 2>&1 || fail "openvox-server is not installed."

puppet_set main certname "$certname"

cadir="$(puppet config print cadir --section server)"
if [ -f "${cadir}/ca_crt.pem" ]; then
  log "CA already exists in ${cadir}"
  exit 0
fi

log "No CA found in ${cadir}; generating one"
systemctl stop puppetserver 2>/dev/null || true
alt_names="$(json_list "${PT_dns_alt_names:-[]}" | paste -sd, -)"
if [ -n "$alt_names" ]; then
  puppetserver ca setup --certname "$certname" --subject-alt-names "$alt_names"
else
  puppetserver ca setup --certname "$certname"
fi
