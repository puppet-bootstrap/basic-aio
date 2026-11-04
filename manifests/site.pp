File {
  # Disable file bucket
  backup => false,
}

# Every host gets the classes from Hiera.  Infrastructure hosts (compile
# masters, CAs, and OpenVoxDB hosts) also get role::server.
lookup('classes', Array[String], 'unique').include

include profile::topology

if $trusted['certname'] in $profile::topology::infrastructure {
  include role::server
}
