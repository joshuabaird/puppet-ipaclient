# == Class: ipaclient
#
# You can use this class to configure your servers to use FreeIPA
#
# === Parameters
#
# Required Parameters (if relying on DNS discovery):
#   join_pw
#
# All Parameters:
#
# $manual_register::       Use DNS autodetection (default) or specify settings yourself for IPA
#
# $domain_dn::             DN, e.g. dc=pixiedust,dc=com
#
# $enable_sudo::           Lookup sudoer rights in IPA
#
# $enrollment_host::       Specific IPA server to register to (e.g., ipa01.pixiedust.com).  Only
#                          needed when $ipa_server is a virtual hostname.
#
# $ipa_domain::            Domain, e.g. pixiedust.com
#
# $ipa_realm::             Realm, e.g. PIXIEDUST.COM
#
# $ipa_server::            Can be a virtual host (e.g. ipa.pixiedust.com), or an array of IPA servers.
#                          When using a virtual host, $enrollment_host must point to a real IPA server.
#
# $ipa_options::           Additional command-line options to pass directly to installer
#
# $join_pw::               One-time password, or registration user's password
#
# $join_user::             When not using one-time passwords, a.k.a. principal in IPA terminology
#
# $mkhomedir::             Automatically make /home/<user> or not
#
# $replicas::              Array of IPA servers (for sudo failover)
#
# $sudo_bindpw::           Password for LDAP sudo bind
#
# === Examples
#
# Discovery register example:
#
#  class { ipaclient:
#       join_pw         => "rainbows"
#  }
#
# Manual register example:
#
#  class { ipaclient:
#       manual_reigster => true,
#       mkhomedir       => true,
#       join_pw         => "unicorns",
#       join_user       => "rainbows",
#       enrollment_host => "ipa01.pixiedust.com",
#       ipa_server      => "ipa.pixiedust.com",
#       ipa_domain      => "pixiedust.com",
#       ipa_realm       => "PIXEDUST.COM",
#       replicas        => ["ipa01.pixiedust.com", "ipa02.pixiedust.com"]
#       domain_dn       => "dc=pixiedust,dc=com",
#       sudo_bindpw     => "sprinkles",
#  }
#
# === Authors
#
# Stephen Benjamin <stephen@bitbin.de>
#
# === Copyright
#
# Copyright 2013 Stephen Benjamin.
# Released under the MIT License. See LICENSE for more information
#
class ipaclient (
  $manual_register = $ipaclient::params::manual_register,
  $mkhomedir       = $ipaclient::params::mkhomedir,
  $join_pw         = $ipaclient::params::join_pw,
  $join_user       = $ipaclient::params::join_user,
  $enrollment_host = $ipaclient::params::enrollment_host,
  $ipa_server      = $ipaclient::params::ipa_server,
  $ipa_domain      = $ipaclient::params::ipa_domain,
  $ipa_realm       = $ipaclient::params::ipa_realm,
  $replicas        = $ipaclient::params::replicas,
  $domain_dn       = $ipaclient::params::domain_dn,
  $enable_sudo     = $ipaclient::params::enable_sudo,
  $sudo_bindpw     = $ipaclient::params::sudo_bindpw,
  $ipa_package     = $ipaclient::params::ipa_package,
  $ipa_installer   = $ipaclient::params::ipa_installer,
  $ipa_options     = $ipaclient::params::ipa_options,
) inherits ipaclient::params {

  validate_array($replicas)
  validate_bool($manual_register, $enable_sudo, $mkhomedir)
  validate_string($join_pw, $join_user, $enrollment_host,
                  $ipa_realm, $domain_dn, $sudo_bindpw,
                  $ipa_package, $ipa_installer, $ipa_options)

  package { $ipa_package:
    ensure      => installed,
  }

  if $join_pw   == 'UNSET' { fail('Require at least a join password') }
  if $ipa_realm != 'UNSET' { $realm   = "--realm ${ipa_realm}" }
  if $join_user            { $user    = "--principal ${join_user}\\@${ipa_realm}"}
  if $mkhomedir            { $homedir = ' --mkhomedir'}
  if $enrollment_host      { $enroll  = "--server ${enrollment_host}" }
  if $ipa_domain           { $dom     = "--domain ${ipa_domain}" }

  # Support $ipa_server as an array
  if $ipa_server and empty($enrollment_host) { 
    if is_array($ipa_server) {
        $server_list = join($ipa_server, " --server ")
    } else {
        $server_list = $ipa_server
    }
    $server = "--server ${server_list}"
  }

  $command = "${ipa_installer} --password ${join_pw} ${realm} --unattended --force ${homedir} ${enroll} ${server} ${dom} ${user} ${ipa_options}"

  # Run the installer
  exec { 'ipa_installer':
    command     => $command,
    unless      => '/usr/sbin/ipa-client-install --unattended 2>&1 | /bin/grep -q "already configured"',
    require     => Package[$ipa_package],
  }

  # Support vip configuration -- only if manual configuration, and only if we're not an ipa server
  if $manual_register == true and $is_ipa_server == false {
    file { '/etc/krb5.conf':
      ensure      => present,
      owner       => root,
      group       => root,
      mode        => '0644',
      content     => template('ipaclient/krb5.erb'),
      require     => Exec['ipa_installer'],
    }
  }

  # Setup sudoers to look at FreeIPA LDAP
  if $enable_sudo {
     # Add nisdomain to /etc/rc.local & make it live
     # According to https://access.redhat.com/site/solutions/180193
     # and https://docs.fedoraproject.org/en-US/Fedora/18/html/FreeIPA_Guide/example-configuring-sudo.html

     exec { 'add_nisdomain':
        command => "/bin/echo nisdomainname ${ipa_domain} >> /etc/rc.local",
        unless  => "/bin/grep -q \"nisdomainname ${ipa_domain}\" /etc/rc.local",
    }

    exec { 'nisdomain_live':
        command => "/bin/nisdomainname ${ipa_domain}",
        unless  => "/bin/nisdomainname | grep -q ${ipa_domain}",
    }

    file { '/etc/sudo-ldap.conf':
      ensure      => present,
      owner       => root,
      group       => root,
      mode        => '0440',
      content     => template('ipaclient/sudo-ldap.erb'),
     }

    if $::operatingsystem == "Fedora" {
        $ldap_service = "sss"
    } else {
        $ldap_service = "ldap"
    }

    augeas { 'nsswitch_sudoers':
      context => '/files/etc/nsswitch.conf',
      changes => [
        "set /files/etc/nsswitch.conf/database[. = 'sudoers'] sudoers",
        "set /files/etc/nsswitch.conf/database[. = 'sudoers']/service[1] files",
        "set /files/etc/nsswitch.conf/database[. = 'sudoers']/service[2] ${ldap_service}",
      ],
    }
  }
}

