class sshkeys {

  $keymaster_storage = "/var/lib/keys"

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

