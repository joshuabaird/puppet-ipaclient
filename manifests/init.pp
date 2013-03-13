class ipaclient ( $enrollment_host = "idm01.example.com",
                  $ipa_server      = "idm-vip.example.com",
                  $ipa_domain      = "example.com",
                  $ipa_realm       = "EXAMPLE.COM",
                  $replicas        = ["idm02.example.com", "idm01.example.com" ],
                  $domain_dn       = "dc=example,dc=com",
                  $join_user       = "Username to join with",
                  $join_pw         = "Password for Joining",
                  $sudo_bindpw     = "Password for sudo-lap dn"
                ) {


    # Command to Run to Join to IPA Domain
    $command_string = "/usr/sbin/ipa-client-install --server $enrollment_host --domain $ipa_domain --realm $ipa_realm  --principal $join_user\@$ipa_realm --password $join_pw --mkhomedir --fixed-primary --unattended --force"

    package { "ipa-client":
        ensure      => installed,
        }

    exec { "ipa_installer":
        command     => $command_string,
        unless      => '/usr/sbin/ipa-client-install --unattended 2>&1 | /bin/grep -q "already configured"',
        require     => Package["ipa-client"],
        }

    # to support vip configuration
    file { "krb5_fixed":
        ensure      => present,
        path        => "/etc/krb5.conf",
        owner       => root,
        group       => root,
        mode        => 0644,
        content     => template("ipaclient/krb5.erb"),
        require     => Exec["ipa_installer"],
    }

    # SUDOers Config
    file { "sudo_ldap":
        ensure      => present,
        path        => "/etc/sudo-ldap.conf",
        owner       => root,
        group       => root,
        mode        => 0440,
        content     => template("ipaclient/sudo-ldap.erb"),
    }


    # FIXME Workaround for problem with augeas nsswitch.conf lens
    # You can do nsswitch augeas like this:
    # augeas { "nsswitch_sudoers":
    #		context	=> "/files/etc/nsswitch.conf",
    #	    changes => [ "set /files/etc/nsswitch.conf/database[*[database = 'sudoers']] sudoers",
    #	                 "set /files/etc/nsswitch.conf/*[self::database = 'sudoers']/service[1] files",
    #		              "set /files/etc/nsswitch.conf/*[self::database = 'sudoers']/service[2] ldap",
    #                  ],
    #       }
    #
    # But it will fail on the second run becasue the "sudoers" nsswitch database is already created.

    exec { "nsswitch_sudoers":
        command     => "/bin/echo sudoers: files ldap >> /etc/nsswitch.conf",
        unless      => "/bin/grep -q 'sudoers: files ldap' /etc/nsswitch.conf",
        require     => [ Exec["ipa_installer"], File["sudo_ldap"] ],
    }

} 
