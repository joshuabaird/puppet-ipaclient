# == Class: ipaclient
#
# This is the ipaclient module. You can use it to configure your servers to use FreeIPA
#
# === Parameters
#
# manual_register
#   use DNS autodetection (default)
#   or specify settings yourself for IPA
#
# mkhomedir
#   automatically make /home/<user> or not
#
# join_pw
#   one-time password, or registraiton user's password
#
# join_user
#   when not using one-time passwords
#
# enrollment_host 
#   specific IPA server to register to
#
# ipa_server
#   an ipa server, can be a VIP
#
# ipa_domain
#   domain, e.g. example.com
#
# ipa_ream:
#   realm, e.g. EXAMPLE.COM
#
# replicas:
#   array of IPA servers (for LDAP failover)
#
# domain_dn:
#   dn, e.g. dc=example,dc=com
#
# enable_sudo:
#   let IPA manage sudoers (default: true)
#
# sudo_bindpw
#   password for LDAP sudo bind
#
# === Examples
#
#  class { ipaclient:
#       manual_reigster => true,
#       mkhomedir       => false,
#       join_pw         => "potatos",
#       join_user       => "register",
#       enrollment_host => "ipa01.example.com",
#       ipa_server      => "ipa-vip.example.com", 
#       ipa_domain      => "example.com",
#       ipa_realm       => "EXAMPLE.COM",
#       replicas        => ["ipa01.example.com, ipa02.example.com"]
#       domain_dn       => "dc=example,dc=com",
#       sudo_bindpw     => "potatoes",
#  }
#
# === Authors
#
# Stephen Benjamin <stephen@bitbin.de>
#
# === Copyright
#
# Copyright 2013 Stephen Benjamin.
# Released under the MIT License.
# See LICENSE for more information

class ipaclient ( $manual_register = false,         
                  $mkhomedir       = true,
                  $join_pw         = "",
                  $join_user       = "",   
                  $enrollment_host = "",  
                  $ipa_server      = "", 
                  $ipa_domain      = "",
                  $ipa_realm       = "",
                  $replicas        = [],
                  $domain_dn       = "",
                  $enable_sudo     = true,
                  $sudo_bindpw     = ""
                ) {



    # Set options for ipa-client-install command:
    
    # If we're not using DNS auto-detection
    if $manual_register {

        if $enrollment_host {  $enroll = " --server $enrollment_host" }
        if $ipa_domain      {  $dom    = " --domain $ipa_domain" }
        if $ipa_relam       {  $realm  = " --realm $ipa_realm" }
        if $join_user       {  $user   = " --principal $join_user\@$ipa_realm"}

    }
    
    if $mkhomedir           {  $homedir = " --mkhomedir"}
    
    # Build the command to join to IPA
    $command = "/usr/sbin/ipa-client-install --password $join_pw --unattended --force $mkhomedir $enroll $dom $relam $user"

    package { "ipa-client":
        ensure      => installed,
    }

    exec { "ipa_installer":
        command     => $command,
        unless      => '/usr/sbin/ipa-client-install --unattended 2>&1 | /bin/grep -q "already configured"',
        require     => Package["ipa-client"],
    }

    # Support vip configuration:
    #   Only if manual configuration, and only if we're not an ipa server
    if $manual_register == true and $is_ipa_server == false {
	    file { "krb5_fixed":
	        ensure      => present,
        	path        => "/etc/krb5.conf",
        	owner       => root,
        	group       => root,
        	mode        => 0644,
        	content     => template("ipaclient/krb5.erb"),
        	require     => Exec["ipa_installer"],
    	    }
    }

    # Add nisdomain to /etc/rc.local & make it live
    # According to https://access.redhat.com/site/solutions/180193
    # Alternative is to enable ypbind which is silly / overkill.
    # This needs a better fix in IPA.

    exec { "add_nisdomain":
        command => "/bin/echo nisdomainname $ipa_domain >> /etc/rc.local",
        unless  => "/bin/grep -q \"nisdomainname $ipa_domain\" /etc/rc.local",
    }

    exec { "nisdomain_live":
        command => "/bin/nisdomainname $ipa_domain",
        unless  => "/bin/nisdomainname | grep -q $ipa_domain",
    }


    if $enable_sudo {
            # SUDOers Config
            file { "sudo_ldap":
                ensure      => present,
                path        => "/etc/sudo-ldap.conf",
                owner       => root,
                group       => root,
                mode        => 0440,
                content     => template("ipaclient/sudo-ldap.erb"),
            }

            # Workaround for problem with augeas nsswitch.conf lens
            #
            # You can do nsswitch augeas like this:
            #
            # augeas { "nsswitch_sudoers":
            #       context => "/files/etc/nsswitch.conf",
            #       changes => [ "set /files/etc/nsswitch.conf/database[*[database = 'sudoers']] sudoers",
            #                    "set /files/etc/nsswitch.conf/*[self::database = 'sudoers']/service[1] files",
            #                     "set /files/etc/nsswitch.conf/*[self::database = 'sudoers']/service[2] ldap",
            #                  ],
            #       }
            #
            # But... it will fail on the second run becasue the "sudoers" nsswitch database is already created.

            exec { "nsswitch_sudoers":
                command     => "/bin/echo sudoers: files ldap >> /etc/nsswitch.conf",
                unless      => "/bin/grep -q 'sudoers: files ldap' /etc/nsswitch.conf",
                require     => [ Exec["ipa_installer"], File["sudo_ldap"] ],
            }

    }

} 
