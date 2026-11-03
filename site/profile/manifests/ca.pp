# @summary Configure the certificate authority
#
# @param autosign
#   `true` to autosign every certificate request, or a list of certnames and
#   domain name globs to write to `autosign.conf`.  `false` leaves autosigning
#   alone.
#
# @example
#   include profile::ca
class profile::ca (
  Variant[Boolean, Array[String[1]]] $autosign = false,
) {
  class { 'bootstrap::ca':
    autosign => $autosign,
  }
}
