#!/bin/bash
# Read-only checks for bootstrap::preflight.  This runs before OpenVox is
# installed, so it uses only standard tools and doesn't load common.sh (which
# needs OpenVox's Ruby).  Problems are reported in the JSON result; the task
# itself only fails if it can't run at all.

set -uo pipefail
export PATH="/usr/sbin:/usr/bin:/sbin:/bin"

errors=()
warnings=()

error() { errors+=("$*"); }
warning() { warnings+=("$*"); }

json_string() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/ }"
  printf '"%s"' "$s"
}

json_array() {
  local first=1 item
  printf '['
  for item in "$@"; do
    [ -n "$item" ] || continue
    [ "$first" -eq 1 ] || printf ','
    first=0
    json_string "$item"
  done
  printf ']'
}

# Bolt passes unset optional parameters as an empty string or "null".
param() {
  local value="${1:-}"
  [ "$value" = 'null' ] && value=''
  printf '%s' "$value"
}

require_fqdn="$(param "${PT_require_fqdn:-false}")"
resolve="$(param "${PT_resolve:-}")"
packages="$(param "${PT_packages:-}")"
postgres_source="$(param "${PT_postgres_source:-}")"
postgres_version="$(param "${PT_postgres_version:-}")"
urls="$(param "${PT_urls:-}")"

# Root
uid="$(id -u)"
[ "$uid" -eq 0 ] || error "Not running as root (uid ${uid}); the bootstrap plans need --run-as root"

# Host name
fqdn="$(hostname -f 2>/dev/null || hostname)"
if [ "$require_fqdn" = 'true' ] && [[ "$fqdn" != *.* ]]; then
  error "hostname -f returns '${fqdn}', which isn't fully qualified; it becomes this host's certname"
fi

# Name resolution
for name in $resolve; do
  if ! getent hosts "$name" >/dev/null 2>&1; then
    error "Can't resolve ${name}"
  fi
done

# Operating system
os_id='unknown'
os_major=''
if [ -r /etc/os-release ]; then
  # shellcheck disable=SC1091
  os_id="$(. /etc/os-release && echo "${ID:-unknown}")"
  # shellcheck disable=SC1091
  os_major="$(. /etc/os-release && echo "${VERSION_ID:-}")"
  os_major="${os_major%%.*}"
fi

# Packages
have_dnf=0
command -v dnf >/dev/null 2>&1 && have_dnf=1

package_available() {
  [ -n "$(timeout 300 dnf -q repoquery --latest-limit 1 "$1" 2>/dev/null)" ]
}

if [ -n "$packages" ] || [ -n "$postgres_source" ]; then
  if [ "$have_dnf" -eq 0 ]; then
    warning "dnf isn't available, so package availability wasn't checked"
  else
    for package in $packages; do
      package_available "$package" || error "Package ${package} isn't available from the configured repositories"
    done

    if [ -n "$postgres_source" ]; then
      case "$postgres_source" in
        pgdg)
          version="${postgres_version:-17}"
          pg_packages="postgresql${version}-server postgresql${version}-contrib"
          ;;
        os)
          version="${postgres_version:-16}"
          if [ "$os_major" = '8' ] || [ "$os_major" = '9' ]; then
            if ! timeout 300 dnf -q module list postgresql 2>/dev/null | grep -Eq "^postgresql[[:space:]]+${version}[[:space:]]"; then
              error "The postgresql:${version} module stream isn't available from the configured repositories"
            fi
            pg_packages=''
          elif [ "$version" = '16' ]; then
            pg_packages='postgresql-server postgresql-contrib'
          else
            pg_packages="postgresql${version}-server postgresql${version}-contrib"
          fi
          ;;
      esac
      for package in $pg_packages; do
        package_available "$package" || error "Package ${package} isn't available from the configured repositories"
      done
      if [ "${version%%.*}" -lt 14 ] 2>/dev/null; then
        error "PostgreSQL ${version} is too old; OpenVoxDB needs PostgreSQL 14 or later"
      fi
    fi
  fi
fi

# URLs
if [ -n "$urls" ]; then
  if ! command -v curl >/dev/null 2>&1; then
    warning "curl isn't available, so URLs weren't checked"
  else
    for url in $urls; do
      curl -sS -o /dev/null --max-time 20 "$url" 2>/dev/null || error "Can't reach ${url}"
    done
  fi
fi

# Existing installation
agent_version=''
if [ -r /opt/puppetlabs/puppet/VERSION ]; then
  agent_version="$(cat /opt/puppetlabs/puppet/VERSION)"
fi

# Firewall
firewalld='inactive'
if command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet firewalld 2>/dev/null; then
  firewalld='active'
fi

printf '{"fqdn":%s,"os":%s,"time":%s,"agent_version":%s,"firewalld":%s,"errors":%s,"warnings":%s}\n' \
  "$(json_string "$fqdn")" \
  "$(json_string "${os_id} ${os_major}")" \
  "$(date +%s)" \
  "$(json_string "$agent_version")" \
  "$(json_string "$firewalld")" \
  "$(json_array "${errors[@]+"${errors[@]}"}")" \
  "$(json_array "${warnings[@]+"${warnings[@]}"}")"
