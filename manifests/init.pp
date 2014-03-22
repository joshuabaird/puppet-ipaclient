# == Class: ipaclient
#
# You can use this class to configure your servers to use FreeIPA
#
# Tested on Fedora 20 and RHEL 6
#
# === Parameters
#
# Required Parameters (if relying on DNS discovery):
#    join_pw
#
# All Parameters:
#
# manual_register   Use DNS autodetection (default) or specify settings yourself for IPA
# domain_dn         DN, e.g. dc=pixiedust,dc=com
# enable_sudo       Lookup sudoer rights in IPA
# enrollment_host   Specific IPA server to register to (e.g., ipa01.pixiedust.com)
# ipa_domain        Domain, e.g. pixiedust.com
# ipa_realm         Realm, e.g. PIXIEDUST.COM
# ipa_server        An ipa server, can be a VIP (e.g. ipa.pixiedust.com)
# join_pw           One-time password, or registration user's password
# join_user         When not using one-time passwords, a.k.a. principal in IPA terminology
# mkhomedir         Putomatically make /home/<user> or not
# replicas          Array of IPA servers (for LDAP failover)
# sudo_bindpw       Password for LDAP sudo bind
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
) inherits ipaclient::params {

  # Required Options
  if $join_pw == 'UNSET' {
    fail('Require at least a join password')
  }

  # Install the IPA client
  package { $ipa_package:
    ensure      => installed,
  }

  # Build the installation comamnd:
  if $join_user             {  $user    = "--principal ${join_user}\@${ipa_realm}"}
  if $mkhomedir             {  $homedir = ' --mkhomedir'}
  if $ipa_realm != 'UNSET'  {  $realm   = "--realm ${ipa_realm}" }
  if $enrollment_host       {  $enroll  = "--server ${enrollment_host}" }
  if $ipa_domain            {  $dom     = "--domain ${ipa_domain}" }

  $command = "${ipa_installer} --password ${join_pw} ${realm} --unattended --force ${homedir} ${enroll} ${dom} ${user}"

  # Run the installer
  exec { 'ipa_installer':
    command     => $command,
    unless      => '/usr/sbin/ipa-client-install --unattended 2>&1 | /bin/grep -q "already configured"',
    require     => Package[$ipa_package],
  }

  # Support vip configuratio -- only if manual configuration, and only if we're not an ipa server
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

  # Setup sudoers to look at FreeIPA LDAP
  if $enable_sudo {
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

