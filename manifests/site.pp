File {
  # Disable file bucket
  backup => false,
}

lookup('classes', Array[String], 'unique').include
