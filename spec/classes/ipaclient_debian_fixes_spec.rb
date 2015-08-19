require 'spec_helper'

describe 'ipaclient::debian_fixes' do
  context "Debian" do
    let :pre_condition do
      "class {'ipaclient':
        password => 'elephants',
      }"
    end

    let :facts do {
      :osfamily               => 'Debian',
      :operatingsystem        => 'Ubuntu',
      :operatingsystemrelease => '14.04'
    } end

    describe_augeas 'debian_ssh_fix', :lens => 'Sshd', :target => 'etc/ssh/sshd_config' do
      it 'should configure sshd correctly' do
        should execute.with_change
        aug_get("AuthorizedKeysCommand").should == "/usr/bin/sss_ssh_authorizedkeys"
        aug_get("GSSAPIAuthentication").should == "yes"
        aug_get("AuthorizedKeysCommandUser").should == "nobody"
        should execute.idempotently
      end
    end

    it "should contain file_line in pam.d common session" do
     should contain_file_line('mkhomedir_pam').with_ensure('present')
    end
  end
end
