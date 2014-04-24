class ipaclient::automount(
    $server   = $ipaclient::params::automount_server,
    $location = $ipaclient::params::automount_location
) inherits ipaclient::params {

  if !empty($server) {
    $opt_server = ['--server',"${server}"]
  }

  if !empty($location) {
    $opt_location = ['--location',"${location}"]
  }

  # regsubst due to PUP-2361 
  $command = regsubst(regsubst(shellquote("/usr/sbin/ipa-client-automount",$opt_server,$opt_location,'--unattended'), "\\\"\\\"", "", "G"), "\s+", " ", "G")

  exec { 'enable_automount':
    command => $command,
    unless  => 'grep -qE "automount:\s+sss" /etc/nsswitch.conf',
  }
}
