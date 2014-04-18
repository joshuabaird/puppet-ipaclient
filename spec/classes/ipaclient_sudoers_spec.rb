require 'spec_helper'

describe 'ipaclient::sudoers' do
  context "Fedora Sudo Configuration" do
    let(:facts) { { :osfamily => 'RedHat', :operatingsystem => 'Fedora' } }

    let(:params) {
      {
        :sudo_bindpw     => "unicorns",
        :replicas        => ["ipa01.example.com", "ipa02.example.com"],
        :domain_dn       => "dc=pixiedust,dc=com",
        :ipa_domain      => "pixiedust.com",
      }
    }

    it "should set the host nisdomain" do
      should contain_exec('add_nisdomain').with({
        'command' => '/bin/echo nisdomainname pixiedust.com >> /etc/rc.local',
      })
    end

    it "should make the nisdomain live now" do
      should contain_exec('nisdomain_live').with({
        'command' => '/bin/nisdomainname pixiedust.com',
      })
    end

      
    it "should configure sudo-ldap" do
      should contain_file('/etc/sudo-ldap.conf').with({
        'ensure'  => 'present',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0440'
      }).with_content(/binddn uid=sudo,cn=sysaccounts,cn=etc,dc=pixiedust,dc=com/)
        .with_content(/bindpw unicorns/)
        .with_content(/sudoers_base ou=SUDOers,dc=pixiedust,dc=com/)
        .with_content(/uri ldap:\/\/ipa01.example.com ldap:\/\/ipa02.example.com/)
    end

    it "should configure nsswitch" do
      should contain_augeas('nsswitch_sudoers')
    end

    describe_augeas 'nsswitch_sudoers', :lens => 'Nsswitch', :target => 'etc/nsswitch.conf' do
      it 'should set sudoers database to files ldap' do
        should execute
        aug_get("database[. = 'sudoers']/service[1]").should == 'files'
        aug_get("database[. = 'sudoers']/service[2]").should == 'sss'
      end
    end
  end

  context 'RHEL-Compatible Sudoers' do
    let(:facts) { { :osfamily => 'RedHat', :operatingsystem => 'CentOS' } }

    let(:params) {
      {
        :sudo_bindpw     => "unicorns",
        :replicas        => ["ipa01.example.com", "ipa02.example.com"],
        :domain_dn       => "dc=pixiedust,dc=com",
        :ipa_domain      => "pixiedust.com",
      }
    }

    it "should configure nsswitch" do
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
end

