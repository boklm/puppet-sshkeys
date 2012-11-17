# Install a key pair into a user's account.
define sshkeys::set_client_key_pair (
  $keyname = '',
  $ensure = 'present',
  $filename = 'id_rsa',
  $group = '',
  $home = '',
  $user
) {
  include sshkeys::var
  File {
    owner   => $user,
    group   => $group ? { '' => $user, default => $group },
    mode    => 600,
    require => [ User[$user], File[$home]],
  }

  $_keyname = $keyname ? { '' => $title, default => $keyname }
  $_home = $home ? { '' => "/home/${user}", default => $home }
  $key_src_file = "${sshkeys::var::keymaster_storage}/${_keyname}/key" # on the keymaster
  $key_tgt_file = "${_home}/.ssh/${filename}" # on the client

  $key_src_content_pub = file("${key_src_file}.pub", "/dev/null")
  if $ensure == "absent" or $key_src_content_pub =~ /^(ssh-...) ([^ ]+)/ {
    $keytype = $1
    $modulus = $2
    file {
      $key_tgt_file:
        ensure  => $ensure,
        content => file($key_src_file, "/dev/null");
      "${key_tgt_file}.pub":
        ensure  => $ensure,
        content => "$keytype $modulus $title\n",
        mode    => 644;
    }
  } else {
    notify { "Private key file $key_src_file for key $title not found on keymaster; skipping ensure => present": }
  }
}
