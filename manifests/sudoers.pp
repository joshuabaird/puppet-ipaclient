# == Class: ipaclient::sudoers
#
# You can use this class to configure your servers for looking up sudo info with FreeIPA
#
# === Parameters
#
# $ipa_domain::            IPA domain name
#
# $domain_dn::             DN, e.g. dc=pixiedust,dc=com
#
# $replicas::              Array of IPA servers (for sudo failover)
#
# $sudo_bindpw::           Password for LDAP sudo bind
#
# === Examples
#
#  class { 'ipaclient::sudoers':
#       replicas        => ["ipa01.pixiedust.com", "ipa02.pixiedust.com"]
#       domain_dn       => "dc=pixiedust,dc=com",
#       sudo_bindpw     => "sprinkles",
#       ipa_domain      => "pixiedust.com",
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
class ipaclient::sudoers (
  $replicas        = $ipaclient::params::replicas,
  $domain_dn       = $ipaclient::params::domain_dn,
  $sudo_bindpw     = $ipaclient::params::sudo_bindpw,
  $ipa_domain      = $ipaclient::params::ipa_domain,
) inherits ipaclient::params {

  validate_array($replicas)
  validate_string($domain_dn, $sudo_bindpw)

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

  if $::operatingsystem == "Fedora" { $ldap_service = "sss" }
  else                              { $ldap_service = "ldap" }

  augeas { 'nsswitch_sudoers':
    context => '/files/etc/nsswitch.conf',
    changes => [
      "set /files/etc/nsswitch.conf/database[. = 'sudoers'] sudoers",
      "set /files/etc/nsswitch.conf/database[. = 'sudoers']/service[1] files",
      "set /files/etc/nsswitch.conf/database[. = 'sudoers']/service[2] ${ldap_service}",
    ],
  }
}

