# Check a name (e.g. key title or filename) for the allowed form
define sshkeys::namecheck (
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
