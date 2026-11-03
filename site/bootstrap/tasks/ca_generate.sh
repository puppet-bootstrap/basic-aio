#!/bin/bash
# shellcheck source=../files/common.sh
# shellcheck disable=SC2154
. "${PT__installdir}/bootstrap/files/common.sh"

require_root

cadir="$(puppet config print cadir --section server)"
[ -f "${cadir}/ca_crt.pem" ] || fail "No CA found in ${cadir}; run bootstrap::ca_setup first."

to_generate=()
while IFS= read -r name; do
  [ -n "$name" ] || continue
  if [ -f "${cadir}/signed/${name}.pem" ]; then
    log "${name}: already signed"
  else
    to_generate+=("$name")
  fi
done < <(json_list "${PT_certnames:-[]}")

[ "${#to_generate[@]}" -gt 0 ] || exit 0

# Certificates for the CA API have to be signed offline.
running=false
if systemctl -q is-active puppetserver; then
  running=true
  log "Stopping puppetserver"
  systemctl stop puppetserver
fi

args=(--certname "$(IFS=,; echo "${to_generate[*]}")" --ca-client --force)
alt_names="$(json_list "${PT_dns_alt_names:-[]}" | paste -sd, -)"
if [ -n "$alt_names" ]; then
  args+=(--subject-alt-names "$alt_names")
fi

log "Generating: ${to_generate[*]}"
status=0
puppetserver ca generate "${args[@]}" || status=$?

if [ "$running" = true ]; then
  log "Starting puppetserver"
  systemctl start puppetserver
fi

exit "$status"
