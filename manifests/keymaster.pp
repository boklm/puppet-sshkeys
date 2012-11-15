# Keymaster host:
# Create key storage; create, regenerate, and remove key pairs
class sshkeys::keymaster {
  include sshkeys
  file { $sshkeys::keymaster_storage:
    ensure => directory,
    owner  => puppet,
    group  => puppet,
    mode   => 644,
  }
  # Realize all virtual master keys
  Sshkeys::Setup_key_master <| |>
}
