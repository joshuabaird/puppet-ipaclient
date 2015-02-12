# == Class: ipaclient::sssd
#
# Configures sssd for IPA
#
# === Parameters
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
class ipaclient::sssd(
  $sssd_sudo_cache_timeout    = $ipaclient::params::sssd_sudo_cache_timeout,
  $sssd_sudo_full_refresh     = $ipaclient::params::sssd_sudo_full_refresh,
  $sssd_sudo_smart_refresh    = $ipaclient::params::sssd_sudo_smart_refresh,
  $sssd_default_domain_suffix = $ipaclient::params::sssd_default_domain_suffix
) inherits ipaclient::params {

  service { 'sssd':
    ensure  => running,
    enable  => true,
  }

  if !empty($sssd_sudo_cache_timeout) {
    augeas { 'sudo_cache_timeout':
      context => '/files/etc/sssd/sssd.conf',
      changes => [
        "set target[1]/entry_cache_sudo_timeout ${sssd_sudo_cache_timeout}",
      ],
      notify => Service['sssd'],
    }
  }

  if !empty($sssd_sudo_full_refresh) {
    augeas { 'sudo_full_refresh':
      context => '/files/etc/sssd/sssd.conf',
      changes => [
        "set target[5]/ldap_sudo_full_refresh_interval ${sssd_sudo_full_refresh}",
      ],
      notify => Service['sssd'],
    }
  }

  if !empty($sssd_sudo_smart_refresh) {
    augeas { 'sudo_smart_refresh':
      context => '/files/etc/sssd/sssd.conf',
      changes => [
        "set target[5]/ldap_sudo_smart_refresh_interval ${sssd_sudo_smart_refresh}",
      ],
      notify => Service['sssd'],
    }
  }

  if !empty($sssd_default_domain_suffix) {
    augeas { 'default_domain_suffix':
      context => '/files/etc/sssd/sssd.conf',
      changes => [
        "set target[2]/default_domain_suffix ${sssd_default_domain_suffix}",
      ],
      notify => Service['sssd'],
    }
  }
}
