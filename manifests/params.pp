# IPAclient Default Settings
class ipaclient::params {

  $manual_register = false
  $mkhomedir       = true
  $join_user       = ''
  $join_pw         = 'UNSET'
  $ipa_realm       = 'UNSET'
  $enrollment_host = ''
  $ipa_server      = ''
  $ipa_domain      = ''
  $ipa_options     = ''
  $replicas        = []
  $domain_dn       = ''
  $enable_sudo     = false
  $sudo_bindpw     = ''
  $ipa_installer = '/usr/sbin/ipa-client-install'

  # Name of IPA package to install
  case $::osfamily {
    RedHat: {
      case $::operatingsystem {
        'fedora': {
          $ipa_package = 'freeipa-client'
        }
        default: {
          $ipa_package = 'ipa-client'
        }
      }
    }
    default: {
      fail("${::hostname}: This module does not support operatingsystem ${::operatingsystem}")
    }
  }
}

