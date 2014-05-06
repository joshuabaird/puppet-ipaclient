# == Class: ipaclient::sudoers
#
# You can use this class to configure your servers for looking up sudo info with FreeIPA
#
# === Parameters
#
# By default, we'll get these values from Facter.
#
# $domain::            IPA domain name
#
# $server::            Comma-separated list of servers
#
# === Examples
#
# class { 'ipaclient::sudoers': }
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
  $server      = $::ipa_server,
  $domain      = $::ipa_domain
) {

  if !empty($server) and !empty($domain) {
    $realm = upcase($domain)

    case $::osfamily {
      RedHat: {
        $libsss_sudo_package = "libsss_sudo"

        exec { 'nisdomain':
          command => shellquote('/usr/sbin/authconfig','--nisdomain',"${domain}",'--update'),
          unless  => shellquote('/bin/grep','-q',"NISDOMAIN=${domain}",'/etc/sysconfig/network'),
        }
      }
      Debian: {
        $libsss_sudo_package = "libsss-sudo"
        $safe_domain = shellquote($domain)
        
        exec { "nisdomain_live":
          command => "/bin/nisdomainname ${safe_domain}",
          unless => "/bin/nisdomainname | grep -q ${safe_domain}",
        }

        file { '/etc/init/nisdomain.conf':
          owner   => 'root',
          group   => 'root',
          mode    => 0755,
          content => template('ipaclient/nisdomain.erb'),
        }
      }
    }

    package { $libsss_sudo_package:
      ensure  => installed,
    }

    service { 'sssd':
      ensure  => running,
      enable  => true,    
      require => Package[$libsss_sudo_package],
    }

    augeas { 'nsswitch_sudoers':
      context => '/files/etc/nsswitch.conf',
      changes => [
        "set database[. = 'sudoers'] sudoers",
        "set database[. = 'sudoers']/service[1] files",
        "set database[. = 'sudoers']/service[2] sss",
      ],
    }

    if (versioncmp($::sssd_version, '1.11') >= 0) {
      # SSSD versions >= 1.11 support using the IPA sudo_provider
      # which is vastly simpler to configure
      augeas { 'sssd':
        context => '/files/etc/sssd/sssd.conf',
        changes => [
          'set target[1]/sudo_provider ipa',
          'set target[2]/services "nss, pam, ssh, sudo"',
        ],
        notify  => Service['sssd'],
      }
    } else {
      # SSSD < 1.11 needs to use the more complex LDAP provider
      $krb5_server = join(values_at(split($server, ","), 0), "")
      $dn = join(prefix(split($domain, "\."), "dc="), ",")

      # Generate correct ldap:// uris, but _srv_ doesn't get a prefix, this is all a bit tricky and ugly
      $tmp_ldap_uri = join(prefix(delete(split(regsubst($server, "\s+", "", "G"), ","), "_srv_"), "ldap://"), ", ")

      if member(split(regsubst($server, "\s+", "", "G") , ","), "_srv_") {
          if empty($tmp_ldap_uri) {
              $ldap_uri = "_srv_"
          } else {
              $ldap_uri = "_srv_, ${tmp_ldap_uri}"
          }
      } else {
          $ldap_uri = $tmp_ldap_uri
      }

      augeas { 'sssd':
        context => '/files/etc/sssd/sssd.conf',
        changes => [
          'set target[1]/sudo_provider ldap',
          "set target[1]/ldap_uri \"${ldap_uri}\"",
          "set target[1]/ldap_sudo_search_base ou=SUDOers,${dn}",
          'set target[1]/ldap_sasl_mech GSSAPI',
          "set target[1]/ldap_sasl_authid host/${::fqdn}",
          "set target[1]/ldap_sasl_realm ${realm}",
          "set target[1]/krb5_server ${krb5_server}", 
          'set target[2]/services "nss, pam, ssh, sudo"',
        ],
        notify  => Service['sssd'],
      }
    }
  }
}

