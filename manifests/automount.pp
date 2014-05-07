# == Class: ipaclient::automount
#
#Configure automount and NFS for IPA
#
# === Parameters
#
# All are optional.
#
# $server::     IPA server to connect to
#
# $location::   Automount location
#
# === Authors
#
# Stephen Benjamin <stephen@bitbin.de>
#
# === Copyright
#
# Copyright 2014 Stephen Benjamin.
# Released under the MIT License. See LICENSE for more information
#
class ipaclient::automount(
    $server   = $ipaclient::params::automount_server,
    $location = $ipaclient::params::automount_location
) inherits ipaclient::params {

  if !empty($server) {
    $opt_server = ['--server',"${server}"]
  } else { 
    $opt_server = ''
  }

  if !empty($location) {
    $opt_location = ['--location',"${location}"]
  } else { 
    $opt_location = ''
  }

  $command = shellquote(delete(flatten(["/usr/sbin/ipa-client-automount",$opt_server,$opt_location,'--unattended']), ''))

  exec { 'enable_automount':
    command => $command,
    unless  => 'grep -qE "automount:\s+sss" /etc/nsswitch.conf',
  }
}
