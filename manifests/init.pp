class sshkeys (
  $keymaster_storage = $sshkeys::var::keymaster_storage,
  $home = $sshkeys::var::home  
 )
  inherits sshkeys::var  {
 }
