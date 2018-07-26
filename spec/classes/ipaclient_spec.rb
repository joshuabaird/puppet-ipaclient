require 'spec_helper'

describe 'ipaclient' do
  context "Fedora" do
    let :facts do {
      :osfamily               => 'RedHat',
      :operatingsystem        => 'Fedora',
      :operatingsystemrelease => '21',
      :ipa_enrolled           => false,
    } end

    describe "without required options" do
      let(:params) do {
        :mkhomedir => 'true'
      } end

      it "should fail without required options" do
        expect { should compile }.to raise_error(/Require at least a join password/)
      end
    end

    describe "discovery register" do
      let(:params) do {
        :mkhomedir => true,
        :password  => "unicorns",
        :realm     => false,
        :principal => false,
        :domain    => false,
      } end

      it "should have the right package name"  do
        should contain_package('freeipa-client')
      end

      it "should generate the right command" do
        should contain_exec('ipa_installer').
          with_command("/usr/sbin/ipa-client-install --password unicorns --mkhomedir --unattended")
      end

    end

    describe "arbitrary options" do
      let :params do {
        :password  => "unicorns",
        :options   => "--permit",
        :realm     => false,
        :principal => false,
        :domain    => false
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
        :password  => "unicorns",
        :realm     => false,
        :principal => false,
        :domain    => false
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
        :password  => "unicorns",
        :realm     => false,
        :principal => false,
        :domain    => false
      } end

      it "should generate the right command" do
        should contain_exec('ipa_installer').
          with_command("/usr/sbin/ipa-client-install --password unicorns --mkhomedir --server ipa01.example.com --unattended")
      end
    end
  end

  context 'RedHat' do
    let :facts do {
      :osfamily               => 'RedHat',
      :operatingsystem        => 'RedHat',
      :operatingsystemrelease => '7.2',
      :sssd_services          => 'nss, pam, ssh',
      :ipa_enrolled           => false
    } end

    describe "full manual register" do
      let :params do {
        :mkhomedir => 'false',
        :password  => "unicorns",
        :principal => "rainbows",
        :server    => "ipa01.pixiedust.com",
        :domain    => "pixiedust.com",
        :hostname  => "client.pixiedust.com",
        :realm     => "PIXIEDUST.COM",
        :sudo      => false,
        :automount => true,
        :automount_location => 'home'
      } end

      it "should install the right package" do
        should contain_package('ipa-client').with({
          'ensure'  => 'installed'
        })
      end

      it "should generate the correct command" do
        should contain_exec('ipa_installer').with_command("/usr/sbin/ipa-client-install --realm PIXIEDUST.COM --password unicorns --principal rainbows@PIXIEDUST.COM --domain pixiedust.com --hostname client.pixiedust.com --server ipa01.pixiedust.com --no-sudo --unattended")
      end

      it "should not configure sudoers" do
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

    end
  end

  context 'Non-Fedora RedHat OS' do
    let :facts do {
      :osfamily               => 'RedHat',
      :operatingsystem        => 'Whatever',
      :operatingsystemrelease => 'Whatever',
      :ipa_enrolled           => true
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
      expect { should compile }.to raise_error(/does not support/)
    end
  end
end
