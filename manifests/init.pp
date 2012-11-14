class sshkeys {

  $keymaster_storage = "/var/lib/keys"

  Notify { withpath => false }


  # Declare keys.  The approach here is just to define a bunch of
  # virtual resources, representing key files on the keymaster, client,
  # and server.  The virtual keys are then realized by
  # sshkeys::{keymaster,client,server}, respectively.  The reason for
  # doing things that way is that it makes sshkeys::key into a "one
  # stop shop" where users can declare their keys with all of their
  # parameters, whether those parameters apply to the keymaster, server,
  # or client.  The real work of creating, installing, and removing keys
  # is done in the private definitions called by the virtual resources:
  # ssh_auth_key_{master,server,client}.
  define key (
    $ensure = "present",
    $filename = "",
    $force = false,
    $group = "puppet",
    $home = "",
    $keytype = "rsa",
    $length = 2048,
    $maxdays = "",
    $mindate = "",
    $options = "",
    $user = ""
  ) {
    ssh_auth_key_namecheck { "${title}-title": parm => "title", value => $title }

    # apply defaults
    $_filename = $filename ? { "" => "id_${keytype}", default => $filename }
    $_length = $keytype ? { "rsa" => $length, "dsa" => 1024 }
    $_user = $user ? {
      ""      => regsubst($title, '^([^@]*)@?.*$', '\1'),
      default => $user,
    }
    $_home = $home ? { "" => "/home/$_user",  default => $home }

    ssh_auth_key_namecheck { "${title}-filename":
      parm => "filename",
      value => $_filename,
    }

    @sshkeys::setup_key_master { $title:
      ensure  => $ensure,
      force   => $force,
      keytype => $keytype,
      length  => $_length,
      maxdays => $maxdays,
      mindate => $mindate,
    }
    @setup_client_key_pair { $title:
      ensure   => $ensure,
      filename => $_filename,
      group    => $group,
      home     => $_home,
      user     => $_user,
    }
    @ssh_auth_key_server { $title:
      ensure  => $ensure,
      group   => $group,
      home    => $_home,
      options => $options,
      user    => $_user,
    }
  }


  # Keymaster host:
  # Create key storage; create, regenerate, and remove key pairs
  class keymaster {
    file { $sshkeys::keymaster_storage:
      ensure => directory,
      owner  => puppet,
      group  => puppet,
      mode   => 644,
    }
    # Realize all virtual master keys
    Sshkeys::Setup_key_master <| |>
  }


  # Install generated key pairs onto clients
  define client (
    $ensure = "",
    $filename = "",
    $group = "",
    $home = "",
    $user = ""
  ) {
    # Realize the virtual client keys.
    # Override the defaults set in sshkeys::key, as needed.
    if $ensure {
      Setup_client_key_pair <| title == $title |> {
	ensure   => $ensure,
      }
    }
    if $filename {
      Setup_client_key_pair <| title == $title |> {
	filename => $filename,
      }
    }
    if $group {
      Setup_client_key_pair <| title == $title |> {
	group    => $group,
      }
    }
    if $user {
      Setup_client_key_pair <| title == $title |> {
	user => $user,
	home => "/home/$user",
      }
    }
    if $home {
      Setup_client_key_pair <| title == $title |> {
	home => $home
      }
    }
    realize Setup_client_key_pair[$title]
  }


  # Install public keys onto clients
  define server (
    $ensure = "",
    $group = "",
    $home = "",
    $options = "",
    $user = ""
  ) {
    # Realize the virtual server keys.
    # Override the defaults set in sshkeys::key, as needed.
    if $ensure {
      Ssh_auth_key_server <| title == $title |> {
	ensure  => $ensure,
      }
    }
    if $group {
      Ssh_auth_key_server <| title == $title |> {
	group   => $group,
      }
    }
    if $options {
      Ssh_auth_key_server <| title == $title |> {
	options => $options,
      }
    }

    if $user {
      Ssh_auth_key_server <| title == $title |> {
	user => $user, home => "/home/$user",
      }
    }
    if $home {
      Ssh_auth_key_server <| title == $title |> {
	home => $home,
      }
    }
    realize Ssh_auth_key_server[$title]
  }
}


# Install a key pair into a user's account.
# This definition is private, i.e. it is not intended to be called directly by users.
define setup_client_key_pair (
  $ensure,
  $filename,
  $group,
  $home,
  $user
) {
  File {
    owner   => $user,
    group   => $group,
    mode    => 600,
    require => [ User[$user], File[$home]],
  }

  $key_src_file = "${sshkeys::keymaster_storage}/${title}/key" # on the keymaster
  $key_tgt_file = "${home}/.ssh/${filename}" # on the client

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


# Install a public key into a server user's authorized_keys(5) file.
# This definition is private, i.e. it is not intended to be called directly by users.
define ssh_auth_key_server (
  $ensure,
  $group,
  $home,
  $options,
  $user
) {
  # on the keymaster:
  $key_src_dir = "${sshkeys::keymaster_storage}/${title}"
  $key_src_file = "${key_src_dir}/key.pub"
  # on the server:
  $key_tgt_file = "${home}/.ssh/authorized_keys"

  File {
    owner   => $user,
    group   => $group,
    require => User[$user],
    mode    => 600,
  }
  Ssh_authorized_key {
    user   => $user,
    target => $key_tgt_file,
  }

  if $ensure == "absent" {
    ssh_authorized_key { $title:
      ensure => "absent",
    }
  }
  else {
    $key_src_content = file($key_src_file, "/dev/null")
    if ! $key_src_content {
      notify {
	"Public key file $key_src_file for key $title not found on keymaster; skipping ensure => present":
      }
    } else {
      if $ensure == "present" and $key_src_content !~ /^(ssh-...) ([^ ]*)/ {
	err("Can't parse public key file $key_src_file")
	notify {
	  "Can't parse public key file $key_src_file for key $title on the keymaster: skipping ensure => $ensure":
	}
      } else {
	$keytype = $1
	$modulus = $2
	ssh_authorized_key { $title:
	  ensure  => "present",
	  type    => $keytype,
	  key     => $modulus,
	  options => $options ? { "" => undef, default => $options },
	}
      }
    }
  }
}


# Check a name (e.g. key title or filename) for the allowed form
define ssh_auth_key_namecheck (
  $parm,
  $value
) {
  if $value !~ /^[A-Za-z0-9]/ {
    fail("sshkeys::key: $parm '$value' not allowed: must begin with a letter or digit")
  }
  if $value !~ /^[A-Za-z0-9_.:@-]+$/ {
    fail("sshkeys::key: $parm '$value' not allowed: may only contain the characters A-Za-z0-9_.:@-")
  }
}
