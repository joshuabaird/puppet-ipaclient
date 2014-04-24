# == Class: ipaclient
#
# You can use this class to configure your servers to use FreeIPA
#
# === Parameters
#
# Minimum Parameters (if relying on DNS discovery):
#   password
#
# All Parameters:
#
# $automount::             Enable automount
#                          Default: false
#
# $automount_location::    Automounter location
#
# $automount_server::      Automounter server
#
# $domain::                Domain, e.g. pixiedust.com
#
# $fixed_primary::         Used a fixed primary
#                          Default: false
#
# $installer::             IPA install command
#
# $mkhomedir::             Automatically make /home/<user> or not
#                          Default: true
# $options::               Additional command-line options to pass directly to installer
#
# $package::               Package to install
#
# $password::              One-time password, or registration user's password
#
# $principal::             Kerberos principal when not using one-time passwords
#
# $realm::                 Realm, e.g. PIXIEDUST.COM
#
# $server::                Can be array or string of IPA servers
#
# $ssh::                   Enable SSH Integation
#                          Default: true
#
# $sudo::                  Enable sudoers management
#                          Default: true
#
#
# === Examples
#
# Discovery register example:
#
#  class { 'ipaclient':
#       password         => "rainbows"
#  }
#
# More complex:
#
#  class { 'ipaclient':
#       mkhomedir          => false,
#       automount          => true,
#       automount_location => "home",
#       password           => "unicorns",
#       domain             => "pixiedust.com",
#       realm              => "PIXEDUST.COM",
#       server             => ["ipa01.pixiedust.com", "ipa02.pixiedust.com"]
#  }
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
class ipaclient (
  $automount          = $ipaclient::params::automount,
  $automount_location = $ipaclient::params::automount_location,
  $automount_server   = $ipaclient::params::automount_server,
  $domain             = $ipaclient::params::domain,
  $fixed_primary      = $ipaclient::params::fixed_primary,
  $installer          = $ipaclient::params::installer,
  $mkhomedir          = $ipaclient::params::mkhomedir,
  $options            = $ipaclient::params::options,
  $package            = $ipaclient::params::package,
  $password           = $ipaclient::params::password,
  $principal          = $ipaclient::params::principal,
  $realm              = $ipaclient::params::realm,
  $server             = $ipaclient::params::server,
  $ssh                = $ipaclient::params::ssh,
  $sudo               = $ipaclient::params::sudo
) inherits ipaclient::params {

  package { $package:
    ensure      => installed,
  }

  if empty($password) {
    fail('Require at least a join password')
  } else {
    $opt_password = ['--password', "${password}"]
  }
  
  if is_array($server) {
    # Transform ['a','b'] -> ['--server','a','--server','b']
    $opt_server = split(join(prefix($server, "--server|"), "|"), '\|')
  } elsif !empty($server) {
    $opt_server = ['--server' ,"${server}"]
  } 

  if $domain    { $opt_domain    = ['--domain', "${domain}"] }
  if $realm     { $opt_realm     = ['--realm', "${realm}"] }
  if $principal { $opt_principal = ['--principal', "${principal}@${realm}"] }
  
  if !str2bool($ssh)          { $opt_ssh           = "--no-ssh" }
  if str2bool($fixed_primary) { $opt_fixed_primary = '--fixed-primary' }
  if str2bool($mkhomedir)     { $opt_mkhomedir     = '--mkhomedir' }

  # regsubst due to PUP-2361
  $command = regsubst(regsubst(shellquote($installer,$opt_realm,$opt_password,$opt_principal,$opt_mkhomedir,$opt_domain,
                               $opt_server,$opt_fixed_primary,$opt_ssh,$options,'--force','--unattended'), "\\\"\\\"", "", "G"), "\s+", " ", "G")

  exec { 'ipa_installer':
    command     => $command,
    unless      => '/usr/sbin/ipa-client-install --unattended 2>&1 | /bin/grep -q "already configured"',
    require     => Package[$package],
  }

  if str2bool($sudo) {
     class { 'ipaclient::sudoers':
        require => Exec["ipa_installer"],
     }
  }

  if str2bool($automount) {
    class { 'ipaclient::automount':
        location => $automount_location,
        server   => $automount_server,
        require  => Exec["ipa_installer"],
    }
  }
}

