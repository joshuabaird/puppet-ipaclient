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

  # Version of IPA client
  case $::osfamily {
    RedHat: {
      case $::operatingsystem {
        'Fedora': {
          if (versioncmp($::operatingsystemrelease, '21') >= 0) {
            $version = '4'
          } else {
            $version = '3'
          }
        }
        default: {
          if (versioncmp($::operatingsystemrelease, '7.1') >= 0) {
            $version = '4'
          } else {
            $version = '3'
          }
        }
      }
    }
    Debian: {
      case $::operatingsystem {
        'Ubuntu': {
          if (versioncmp($::operatingsystemrelease, '15.04') > 0) {
            $version = '4'
          } else {
            $version = '3'
          }
        }
        default: {
          $version = '3'
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

