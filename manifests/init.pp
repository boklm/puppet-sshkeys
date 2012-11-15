class sshkeys {

  $keymaster_storage = "/var/lib/keys"

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
  define create_key (
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
    @sshkeys::setup_authorized_keys { $title:
      ensure  => $ensure,
      group   => $group,
      home    => $_home,
      options => $options,
      user    => $_user,
    }
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
      Sshkeys::Setup_authorized_keys <| title == $title |> {
	ensure  => $ensure,
      }
    }
    if $group {
      Sshkeys::Setup_authorized_keys <| title == $title |> {
	group   => $group,
      }
    }
    if $options {
      Sshkeys::Setup_authorized_keys <| title == $title |> {
	options => $options,
      }
    }

    if $user {
      Sshkeys::Setup_authorized_keys <| title == $title |> {
	user => $user, home => "/home/$user",
      }
    }
    if $home {
      Sshkeys::Setup_authorized_keys <| title == $title |> {
	home => $home,
      }
    }
    realize Sshkeys::Setup_authorized_keys [$title]
  }
}

