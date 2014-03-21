# IPAclient Default Parameters
class ipaclient::params {
  # Whether to manual register or not (if not, IPA will look for  DNS SRV records)
  $manual_register = false

  # Automatically make user home directories
  $mkhomedir       = true

  # Join user and password
  $join_user       = ''
  $join_pw         = 'UNSET'

  # An enrollment host is an actual IPA server to register to
  $enrollment_host = ''

  # IPA server is used for manual configruation, this is
  # normally the same as the enrollment host, but it could
  # also be a load-balanced VIP
  $ipa_server      = ''

  # IPA domain, e.g. example.com
  $ipa_domain      = ''

  # IPA realm, e.g. EXAMPLE.COM
  $ipa_realm       = 'UNSET'

  # List of IPA servers + replicas
  $replicas        = []

  # LDAP D.N., e.g. dc=example,dc=com
  $domain_dn       = ''

  # Enable sudo management, and set password for the sudo bind user
  $enable_sudo     = false
  $sudo_bindpw     = ''

  # Installer location
  $ipa_installer = '/usr/sbin/ipa-client-install'

  # Name of IPA package to install
  case $::osfamily {
    RedHat: {
      case $::operatingsystem {
        RedHat: {
          $ipa_package = 'ipa-client'
        }
        default: {
          $ipa_package = 'freeipa-client'
        }
      }
    }
    default: {
      fail("${::hostname}: This module does not support operatingsystem ${::operatingsystem}")
    }
  }
}

