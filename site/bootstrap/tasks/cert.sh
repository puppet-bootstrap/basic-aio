#!/bin/bash
# shellcheck source=../files/common.sh
# shellcheck disable=SC2154
. "${PT__installdir}/bootstrap/files/common.sh"

require_root

action="${PT_action:?action is required}"
certname="${PT_certname:?certname is required}"

puppet_set main certname "$certname"

alt_names="$(json_list "${PT_dns_alt_names:-[]}" | paste -sd, -)"

hostcert="$(puppet config print hostcert --section main)"
requestdir="$(puppet config print requestdir --section main)"

case "$action" in
  request)
    if [ -f "$hostcert" ]; then
      log "${certname} already has a certificate; nothing to request"
      if [ -n "$alt_names" ]; then
        log "Note: dns_alt_names only apply to new CSRs. To change them, clean and re-issue this cert."
      fi
      exit 0
    fi
    if [ -n "$alt_names" ] && [ ! -f "${requestdir}/${certname}.pem" ]; then
      puppet_set main dns_alt_names "$alt_names"
    fi
    # A local CSR doesn't mean the CA has it (the submission could have
    # failed), so always submit.  If the CA already has a request (or a
    # certificate) for this name, `puppet ssl` reports a conflict.  A pending
    # request gets signed next; a certificate that doesn't match this host's
    # key makes the download step fail.
    if ! output="$(puppet ssl submit_request --certname "$certname" 2>&1)"; then
      if echo "$output" | grep -q 'due to a conflict on the server'; then
        log "The CA already has a request for ${certname}"
      else
        echo "$output" >&2
        fail "Submitting the certificate request for ${certname} failed"
      fi
    else
      echo "$output"
    fi
    ;;
  download)
    if [ -f "$hostcert" ]; then
      log "${certname} already has a certificate"
    else
      puppet ssl download_cert --certname "$certname"
    fi
    puppet ssl verify --certname "$certname"
    # Don't leave dns_alt_names in puppet.conf; it is only needed for the CSR.
    if [ -n "$(puppet config print dns_alt_names --section main)" ]; then
      puppet config delete dns_alt_names --section main
    fi
    ;;
esac
