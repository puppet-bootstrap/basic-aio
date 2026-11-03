File {
  # Disable file bucket
  backup => false,
}

# Infrastructure hosts (compile masters, CAs, and OpenVoxDB hosts) get
# role::server; everything else gets the classes from Hiera.
include profile::topology

if $trusted['certname'] in $profile::topology::infrastructure {
  include role::server
} else {
  lookup('classes', Array[String], 'unique').include
}
