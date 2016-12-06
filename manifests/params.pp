# == Class: ipaclient::params
#
# Default parameters for the ipaclient module
#
class ipaclient::params {

  $server         = ''
  $domain         = ''
  $realm          = ''
  $principal      = ''
  $password       = ''
  $ntp_server     = ''
  $ssh            = true
  $sshd           = true
  $automount      = false
  $mkhomedir      = true
  $sudo           = true
  $hostname       = $::fqdn
  $fixed_primary  = false
  $options        = ''
  $installer      = '/usr/sbin/ipa-client-install'
  $automount_location = ''
  $automount_server   = ''
  $ntp            = true
  $force          = false
  $sssd_sudo_cache_timeout     = ''
  $sssd_sudo_full_refresh      = ''
  $sssd_sudo_smart_refresh     = ''
  $sssd_default_domain_suffix  = ''

  # Determine if client needs manual sudo configuration or not
  # RHEL <=6.5 requires manual configuration
  # RHEL 6.6 includes automatic sudo configuration
  # RHEL 7.0 requires manual confifuration
  # RHEL >=7.1 includes automatic sudo configuration
  case $::osfamily {
    'RedHat': {
      case $::operatingsystem {
        'Fedora': {
          if (versioncmp($::operatingsystemrelease, '21') >= 0) {
            $needs_sudo_config = false 
          } else {
            $needs_sudo_config = true
          }
        }
        default: {
          if (versioncmp($::operatingsystemrelease, '6.6') >= 0) {
            if (versioncmp($::operatingsystemrelease, '7.0') == 0) {
              $needs_sudo_config = true
            } else {
              $needs_sudo_config = false
            }
          } else {
            $needs_sudo_config = true
          }
        }
      }
    }
    'Debian': {
      case $::operatingsystem {
        'Ubuntu': {
          if (versioncmp($::operatingsystemrelease, '15.04') > 0) {
            $needs_sudo_config = false
          } else {
            $needs_sudo_config = true
          }
        }
        default: {
          $needs_sudo_config = true
        }
      }
    }
    default: {
      fail("This module does not support operatingsystem ${::operatingsystem}")
    }
  }

  # Name of IPA package to install
  case $::osfamily {
    'RedHat': {
      case $::operatingsystem {
        'fedora': {
          $package = 'freeipa-client'
        }
        default: {
          $package = 'ipa-client'
        }
      }
    }
    'Debian': {
        $package = 'freeipa-client'
    }
    default: {
      fail("This module does not support operatingsystem ${::operatingsystem}")
    }
  }
}

