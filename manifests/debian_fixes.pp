# == Class: ipaclient::debian_fixes
#
# This class contains a number of fixes to handle quirks in Debian
# FreeIPA clients.
#
class ipaclient::debian_fixes {

  if str2bool($ipaclient::ssh) {
    augeas { 'debian_ssh_fix':
      context => '/files/etc/ssh/sshd_config',
      changes => [
        'set AuthorizedKeysCommand /usr/bin/sss_ssh_authorizedkeys',
        'set GSSAPIAuthentication yes',
        'set AuthorizedKeysCommandUser nobody',
        ]
      }
  }

  if str2bool($ipaclient::mkhomedir) {
    file_line { 'mkhomedir_pam':
      ensure => present,
      line   => 'session required pam_mkhomedir.so',
      path   => '/etc/pam.d/common-session'
    }
  }
}
