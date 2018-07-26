require 'spec_helper'

describe 'ipaclient::automount' do
  context "Fedora" do
    let :facts do {
      :osfamily               => 'RedHat',
      :operatingsystem        => 'Fedora',
      :operatingsystemrelease => '21'
    } end

    describe "no options" do
      it "should configure automount" do
        should contain_exec('enable_automount').with({
         'command' => '/usr/sbin/ipa-client-automount --unattended',
       })
      end
   end

    describe "with location" do
      let :params do {
        :location => 'home'
      } end
      it "should configure automount with location" do
        should contain_exec('enable_automount').with({
          'command' => '/usr/sbin/ipa-client-automount --location home --unattended',
        })
      end
    end

    describe "with server" do
      let :params do {
        :server => 'foo'
      } end
      it "should configure automount with server" do
        should contain_exec('enable_automount').with({
          'command' => '/usr/sbin/ipa-client-automount --server foo --unattended',
        })
      end
    end
  end
end
