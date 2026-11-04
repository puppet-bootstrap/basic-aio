#!/bin/bash
# shellcheck source=../files/common.sh
# shellcheck disable=SC2154
. "${PT__installdir}/bootstrap/files/common.sh"

require_root

cadir="$(puppet config print cadir --section server)"
[ -f "${cadir}/ca_crt.pem" ] || fail "No CA found in ${cadir}; run bootstrap::ca_setup first."

to_sign=()
while IFS= read -r name; do
  [ -n "$name" ] || continue
  if [ -f "${cadir}/signed/${name}.pem" ]; then
    log "${name}: already signed"
  elif [ -f "${cadir}/requests/${name}.pem" ]; then
    to_sign+=("$name")
  else
    fail "${name}: no pending CSR and no signed certificate on this CA"
  fi
done < <(json_list "${PT_certnames:-[]}")

if [ "${#to_sign[@]}" -gt 0 ]; then
  log "Signing: ${to_sign[*]}"
  puppetserver ca sign --certname "$(IFS=,; echo "${to_sign[*]}")"
fi
