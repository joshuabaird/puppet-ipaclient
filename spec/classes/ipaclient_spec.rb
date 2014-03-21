require 'spec_helper'

describe 'ipaclient' do
  let :default_facts do
    { :is_ipa_server   => false }
  end

  context "Automatic install on Fedora with discovery" do
    let(:facts) {
      default_facts.merge({
        :osfamily        => 'RedHat',
        :operatingsystem => 'Fedora',
      })
    }

    let(:params) {
      {
        :manual_register => false,
        :mkhomedir       => true,
        :join_pw         => "unicorns",
      }
    }

    it do
      should contain_package('freeipa-client')
    end

    it do
      should contain_exec('ipa_installer').
        with_command(/\/usr\/sbin\/ipa-client-install\s+--password unicorns\s+--unattended\s+--force\s+--mkhomedir/)
    end
  end

  context 'Manual installation on RHEL with all features' do
    let(:facts) {
      default_facts.merge({
        :osfamily        => 'RedHat',
        :operatingsystem => 'RedHat',
      })
    }

    let(:params) {
      { 
        :manual_register => true,
        :mkhomedir       => false,
        :join_pw         => "unicorns",
        :join_user       => "rainbows",
        :enrollment_host => "ipa01.pixiedust.com",
        :ipa_server      => "ipa.pixiedust.com",
        :ipa_domain      => "pixiedust.com",
        :ipa_realm       => "PIXIEDUST.COM",
        :replicas        => ["ipa01.pixiedust.com, ipa02.pixiedust.com"],
        :domain_dn       => "dc=pixiedust,dc=com",
        :sudo_bindpw     => "unicorns",
        :enable_sudo     => true,
      }
    }

    it do
      should contain_package('ipa-client').with({
        'ensure'  => 'installed'
      })
    end

    it do
      should contain_exec('ipa_installer').with({
        'command' => "/usr/sbin/ipa-client-install --password unicorns --realm PIXIEDUST.COM --unattended --force  --server ipa01.pixiedust.com --domain pixiedust.com --principal rainbows\\@PIXIEDUST.COM",
      })
    end

    it do
      should contain_file('/etc/krb5.conf').with({
        'ensure'  => 'present',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0644',
      }).
        with_content(/kdc = ipa.pixiedust.com:88/).
        with_content(/master_kdc = ipa.pixiedust.com:88/).
        with_content(/admin_server = ipa.pixiedust.com:749/).
        with_content(/default_domain = pixiedust.com/)
    end

    it do
      should contain_exec('add_nisdomain').with({
        'command' => '/bin/echo nisdomainname pixiedust.com >> /etc/rc.local',
      })
    end

    it do
      should contain_exec('nisdomain_live').with({
        'command' => '/bin/nisdomainname pixiedust.com',
      })
    end

      
    it do
      should contain_file('/etc/sudo-ldap.conf').with({
        'ensure'  => 'present',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0440'
      })
    end

    it do
      should contain_augeas('nsswitch_sudoers')
    end

    describe_augeas 'nsswitch_sudoers', :lens => 'Nsswitch', :target => 'etc/nsswitch.conf' do
      it 'should set sudoers database to files ldap' do
        should execute
        aug_get("database[. = 'sudoers']/service[1]").should == 'files'
        aug_get("database[. = 'sudoers']/service[2]").should == 'ldap'
      end
    end
  end

  context "Automatic install on Fedora with all features" do
    let(:facts) {
      default_facts.merge({
        :osfamily        => 'RedHat',
        :operatingsystem => 'Fedora',
      })
    }

    let(:params) {
      {
        :manual_register => true,
        :mkhomedir       => false,
        :join_pw         => "unicorns",
        :join_user       => "rainbows",
        :enrollment_host => "ipa01.pixiedust.com",
        :ipa_server      => "ipa.pixiedust.com",
        :ipa_domain      => "pixiedust.com",
        :ipa_realm       => "PIXIEDUST.COM",
        :replicas        => ["ipa01.pixiedust.com, ipa02.pixiedust.com"],
        :domain_dn       => "dc=pixiedust,dc=com",
        :sudo_bindpw     => "unicorns",
        :enable_sudo     => true,
      }
    }

    it do
      should contain_package('freeipa-client').with({
        'ensure'  => 'installed'
      })
    end

    it do
      should contain_augeas('nsswitch_sudoers')
    end

    # spec for fedora is different, ldap nsswitch service is sss
    describe_augeas 'nsswitch_sudoers', :lens => 'Nsswitch', :target => 'etc/nsswitch.conf' do
      it 'should set sudoers database to files ldap' do
        should execute
        aug_get("database[. = 'sudoers']/service[1]").should == 'files'
        aug_get("database[. = 'sudoers']/service[2]").should == 'sss'
      end
    end
  end
end
