# Install generated key pairs onto clients
define sshkeys::install_client_key_pair (
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
