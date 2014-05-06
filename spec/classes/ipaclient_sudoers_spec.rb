require 'spec_helper'

describe 'ipaclient::sudoers' do
  context "RedHat SSSD < 1.11" do
    let :facts do {
      :ipa_domain    => 'pixiedust.com',
      :fqdn          => 'host.pixiedust.com',
      :sssd_version  => '1.9.2',
      :osfamily      => "RedHat"
    } end

    describe "with srv record" do
      let(:params) do {
        :server => "_srv_, ipa01.pixiedust.com, ipa02.pixiedust.com"
      } end

      it "should set the host nisdomain" do
        should contain_exec('nisdomain').with({
          'command' => '/usr/sbin/authconfig --nisdomain pixiedust.com --update',
        })
      end

      it "should install libsss sudo package" do
        should contain_package("libsss_sudo")
      end

      it "should configure sssd" do
        should contain_augeas('sssd')
      end

      describe_augeas 'sssd', :lens => 'Sssd', :target => 'etc/sssd/sssd.conf' do
        it 'should configure sssd to use ldap sudo provider' do
          should execute.with_change
          aug_get("target[1]/sudo_provider").should == "ldap"
          aug_get("target[1]/ldap_uri").should == "_srv_, ldap://ipa01.pixiedust.com, ldap://ipa02.pixiedust.com"
          aug_get("target[1]/ldap_sudo_search_base").should == "ou=SUDOers,dc=pixiedust,dc=com"
          aug_get("target[1]/ldap_sasl_mech").should == "GSSAPI"
          aug_get("target[1]/ldap_sasl_authid").should == "host/host.pixiedust.com"
          aug_get("target[1]/ldap_sasl_realm").should == "PIXIEDUST.COM"
          aug_get("target[1]/krb5_server").should == "_srv_"
          aug_get("target[2]/services").should == "nss, pam, ssh, sudo"
          should execute.idempotently
        end
      end

      it "should configure nsswitch" do
        should contain_augeas('nsswitch_sudoers')
      end

      describe_augeas 'nsswitch_sudoers', :lens => 'Nsswitch', :target => 'etc/nsswitch.conf' do
        it 'should set sudoers database to files sss' do
          should execute.with_change
          aug_get("database[. = 'sudoers']/service[1]").should == 'files'
          aug_get("database[. = 'sudoers']/service[2]").should == 'sss'
          should execute.idempotently
        end
      end
    end

    describe "without srv records" do
      let :params do {
        :server => "ipa01.pixiedust.com, ipa02.pixiedust.com" 
      } end

      describe_augeas 'sssd', :lens => 'Sssd', :target => 'etc/sssd/sssd.conf' do
        it 'should configure sssd to use ldap sudo provider' do
          should execute.with_change
          aug_get("target[1]/sudo_provider").should == "ldap"
          aug_get("target[1]/ldap_uri").should == "ldap://ipa01.pixiedust.com, ldap://ipa02.pixiedust.com"
          aug_get("target[1]/ldap_sudo_search_base").should == "ou=SUDOers,dc=pixiedust,dc=com"
          aug_get("target[1]/ldap_sasl_mech").should == "GSSAPI"
          aug_get("target[1]/ldap_sasl_authid").should == "host/host.pixiedust.com"
          aug_get("target[1]/ldap_sasl_realm").should == "PIXIEDUST.COM"
          aug_get("target[1]/krb5_server").should == "ipa01.pixiedust.com"
          aug_get("target[2]/services").should == "nss, pam, ssh, sudo"
          should execute.idempotently
        end
      end
    end
  end

  context "RedHat SSSD >= 1.11" do
    let :facts do {
      :ipa_domain    => 'pixiedust.com',
      :ipa_server    => '_srv_, ipa01.pixiedust.com, ipa02.pixiedust.com',
      :fqdn          => 'host.pixiedust.com',
      :sssd_version  => '1.11',
      :osfamily      => 'RedHat',
    } end

    it "should configure sssd" do
      should contain_augeas('sssd')
    end

    describe_augeas 'sssd', :lens => 'Sssd', :target => 'etc/sssd/sssd.conf' do
      it 'should configure sssd to use ipa sudo provider' do
        should execute.with_change
        aug_get("target[1]/sudo_provider").should == "ipa"
        aug_get("target[2]/services").should == "nss, pam, ssh, sudo"
        should execute.idempotently
      end
    end
  end

  context "Debian SSSD >= 1.11" do
    let :facts do {
      :ipa_domain    => 'pixiedust.com',
      :fqdn          => 'host.pixiedust.com',
      :sssd_version  => '1.9.2',
      :osfamily      => "Debian"
    } end

    let(:params) do {
      :server => "_srv_, ipa01.pixiedust.com, ipa02.pixiedust.com"
    } end

    it "should install libsss sudo package" do
      should contain_package("libsss-sudo")
    end

    it "should set the host nisdomain" do
      should contain_exec('nisdomain_live').with({
        'command' => '/bin/nisdomainname pixiedust.com'
      })
    end

    it "should make the nisdomain persistent on boot" do
      should contain_file('/etc/init/nisdomain.conf').
        with_content(/\/bin\/nisdomainname pixiedust.com/).
        with_content(/start on runlevel \[2345\]/)
    end
  end
end
