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
  $fixed_primary  = false
  $options        = ''
  $installer      = '/usr/sbin/ipa-client-install'
  $automount_location = ''
  $automount_server   = ''
  $ntp            = true
  $force          = false

  # Determine if client needs manual sudo configuration or not
  # RHEL =>6.6 sudo configuration is automatic 
  case $::osfamily {
    RedHat: {
      case $::operatingsystem {
        'Fedora': {
          if (versioncmp($::operatingsystemrelease, '21') >= 0) {
            $needs_sudo_config = '0'
          } else {
            $needs_sudo_config = '1'
          }
        }
        default: {
          if (versioncmp($::operatingsystemrelease, '6.6') >= 0) {
            $needs_sudo_config = '0'
          } else {
            $needs_sudo_config = '1'
          }
        }
      }
    }
    Debian: {
      case $::operatingsystem {
        'Ubuntu': {
          if (versioncmp($::operatingsystemrelease, '15.04') > 0) {
            $needs_sudo_config = '0'
          } else {
            $needs_sudo_config = '1'
          }
        }
        default: {
          $needs_sudo_config = '1'
        }
      }
    }
    default: {
      fail("This module does not support operatingsystem ${::operatingsystem}")
    }
  }

  # Name of IPA package to install
  case $::osfamily {
    RedHat: {
      case $::operatingsystem {
        'fedora': {
          $package = 'freeipa-client'
        }
        default: {
          $package = 'ipa-client'
        }
      }
    }
    Debian: {
        $package = 'freeipa-client'
    }
    default: {
      fail("This module does not support operatingsystem ${::operatingsystem}")
    }
  }
}

