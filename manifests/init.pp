class sshkeys (
    $manual_keys = {}
) {
    create_resources('sshkeys::manual_authorized_key',hiera_hash('sshkeys::manual_keys', $manual_keys))
}
