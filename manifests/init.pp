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
    sshkeys::namecheck { "${title}-title": parm => "title", value => $title }

    # apply defaults
    $_filename = $filename ? { "" => "id_${keytype}", default => $filename }
    $_length = $keytype ? { "rsa" => $length, "dsa" => 1024 }
    $_user = $user ? {
      ""      => regsubst($title, '^([^@]*)@?.*$', '\1'),
      default => $user,
    }
    $_home = $home ? { "" => "/home/$_user",  default => $home }

    sshkeys::namecheck { "${title}-filename":
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
    @sshkeys::setup_client_key_pair { $title:
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
      Sshkeys::Setup_client_key_pair <| title == $title |> {
	ensure   => $ensure,
      }
    }
    if $filename {
      Sshkeys::Setup_client_key_pair <| title == $title |> {
	filename => $filename,
      }
    }
    if $group {
      Sshkeys::Setup_client_key_pair <| title == $title |> {
	group    => $group,
      }
    }
    if $user {
      Sshkeys::Setup_client_key_pair <| title == $title |> {
	user => $user,
	home => "/home/$user",
      }
    }
    if $home {
      Sshkeys::Setup_client_key_pair <| title == $title |> {
	home => $home
      }
    }
    realize Sshkeys::Setup_client_key_pair[$title]
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

