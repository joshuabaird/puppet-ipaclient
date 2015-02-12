require 'spec_helper'

describe 'ipaclient' do
  context "Fedora" do
    let :facts do {
      :osfamily        => 'RedHat',
      :operatingsystem => 'Fedora'
    } end

    describe "without required options" do
      let(:params) do {
        :mkhomedir => 'true'
      } end

      it "should fail without required options" do
        expect { subject }.to raise_error(/Require at least a join password/)
      end
    end

    describe "discovery register" do
      let(:params) do {
        :mkhomedir => true,
        :password  => "unicorns"
      } end

      it "should have the right package name"  do
        should contain_package('freeipa-client')
      end

      it "should generate the right command" do
        should contain_exec('ipa_installer').
          with_command("/usr/sbin/ipa-client-install --password unicorns --mkhomedir --unattended")
      end

      it "should configure sudo" do
        should contain_class('ipaclient::sudoers')
      end
    end

    describe "arbitrary options" do
      let :params do {
        :password => "unicorns",
        :options  => "--permit"
      } end

      it "should generate the right command" do
        should contain_exec('ipa_installer').
          with_command("/usr/sbin/ipa-client-install --password unicorns --mkhomedir --permit --unattended")
      end
    end

    describe "server can be an array" do
      let :params do {
        :mkhomedir => true,
        :server    => ["ipa01.example.com", "ipa02.example.com"],
        :password  => "unicorns"
      } end

      it "should generate the right command" do
        should contain_exec('ipa_installer').
          with_command('/usr/sbin/ipa-client-install --password unicorns --mkhomedir --server ipa01.example.com --server ipa02.example.com --unattended')
      end
    end

    describe "server can be a string" do
      let :params do {
        :mkhomedir => true,
        :server    => "ipa01.example.com",
        :password  => "unicorns"
      } end

      it "should generate the right command" do
        should contain_exec('ipa_installer').
          with_command("/usr/sbin/ipa-client-install --password unicorns --mkhomedir --server ipa01.example.com --unattended")
      end
    end
  end

  context 'RedHat' do
    let :facts do {
      :osfamily        => 'RedHat',
      :operatingsystem => 'RedHat',
      :sssd_services   => 'nss, pam, ssh'
    } end

    describe "full manual register" do
      let :params do {
        :mkhomedir => 'false',
        :password  => "unicorns",
        :principal => "rainbows",
        :server    => "ipa01.pixiedust.com",
        :domain    => "pixiedust.com",
        :realm     => "PIXIEDUST.COM",
        :sudo      => false,
        :automount => true,
        :automount_location => 'home',
        :ntp => false,
        :sshd => false,
        :force => true 
      } end

      it "should install the right package" do
        should contain_package('ipa-client').with({
          'ensure'  => 'installed'
        })
      end

      it "should generate the correct command" do
        should contain_exec('ipa_installer').with_command("/usr/sbin/ipa-client-install --realm PIXIEDUST.COM --password unicorns --principal rainbows@PIXIEDUST.COM --domain pixiedust.com --server ipa01.pixiedust.com --no-sshd --no-ntp --no-sudo --force --unattended")
      end

      it "should not configure sudoers" do
        should_not contain_class('ipaclient::sudoers')
      end
    end

    describe "with automount and sudoers for ipa-client 4" do
      let :params do {
          :password  => 'unicorns',
          :principal => 'rainbows',
          :server    => 'ipa01.pixiedust.com',
          :domain    => 'pixiedust.com',
          :realm     => 'PIXIEDUST.COM',
          :automount => true,
          :automount_location => 'home',
          :sudo      => true,
          :needs_sudo_config   => '0'
      } end

      it "should not configure sudo" do
        should_not contain_class('ipaclient::sudoers')
      end
    end

    describe "with automount and sudoers" do
      let :params do {
          :mkhomedir => 'false',
          :password  => "unicorns",
          :principal => "rainbows",
          :server    => "ipa01.pixiedust.com",
          :domain    => "pixiedust.com",
          :realm     => "PIXIEDUST.COM",
          :sudo      => true,
          :automount => true,
          :automount_location => 'home'
      } end

      it "should configure sssd" do
        should contain_augeas('sssd')
      end

      describe_augeas 'sssd', :lens => 'Sssd', :target => 'etc/sssd/sssd.conf' do
        it 'should configure sssd to use ipa sudo provider with autofs' do
          should execute.with_change
          aug_get("target[2]/services").should == "nss, pam, ssh, autofs, sudo"
          should execute.idempotently
        end
      end
    end
  end

  context 'Non-Fedora RedHat OS' do
    let :facts do {
      :osfamily        => 'RedHat',
      :operatingsystem => 'Whatever'
    } end

    let :params do {
      :mkhomedir => true,
      :password  => "unicorns"
    } end

    it "should have the right package name"  do
      should contain_package('ipa-client')
    end
  end

  context 'unsupported operating system' do
    let :facts do {
      :operatingsystem => 'unsupported',
      :osfamily        => 'Linux'
    } end

    it 'should fail' do
      expect { subject }.to raise_error(/does not support/)
    end
  end

  context 'Debian' do
    let :facts do {
      :osfamily  => 'Debian',
    } end

    let :params do {
      :mkhomedir => 'true',
      :password  => "unicorns",
    } end

    it 'should include debian_fixes' do
      should contain_class('ipaclient::debian_fixes')
    end
  end
end
