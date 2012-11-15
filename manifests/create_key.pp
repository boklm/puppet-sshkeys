define sshkeys::create_key (
  $ensure = "present",
  $filename = "",
  $force = false,
  $keytype = "rsa",
  $length = 2048,
  $maxdays = "",
  $mindate = "",
) {
  sshkeys::namecheck { "${title}-title": parm => "title", value => $title }

  # apply defaults
  $_filename = $filename ? { "" => "id_${keytype}", default => $filename }
  $_length = $keytype ? { "rsa" => $length, "dsa" => 1024 }

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
}
