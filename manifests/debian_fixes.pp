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
      line   => 'session required pam_mkhomedir.so',
      ensure => present,
      path   => '/etc/pam.d/common-session'
    }
  }
}
