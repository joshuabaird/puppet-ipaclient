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
  $automount      = false
  $mkhomedir      = true
  $sudo           = true
  $fixed_primary  = false
  $options        = ''
  $installer      = '/usr/sbin/ipa-client-install'
  $automount_location = ''
  $automount_server   = ''

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

