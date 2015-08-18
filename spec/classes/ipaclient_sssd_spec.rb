require 'spec_helper'

describe 'ipaclient::sssd' do
  context "RedHat" do
    let :facts do {
      :ipa_domain                 => 'pixiedust.com',
      :fqdn                       => 'host.pixiedust.com',
      :osfamily                   => 'RedHat',
    } end
    let :params do {
      :sssd_sudo_cache_timeout    => '1800',
      :sssd_sudo_full_refresh     => '10800',
      :sssd_sudo_smart_refresh    => '600',
      :sssd_default_domain_suffix => 'pixiedust.com',
    } end

    it "should configure custom cache and refresh intervals" do
      should contain_augeas('sudo_cache_timeout')
      should contain_augeas('sudo_full_refresh')
      should contain_augeas('sudo_smart_refresh')
    end

    describe_augeas 'sudo_cache_timeout', :lens => 'Sssd', :target => '/etc/sssd/sssd.conf' do
      it "should configure custom sssd cache timeout" do
        should execute.with_change
        aug_get("target[1]/entry_cache_sudo_timeout").should == '1800'
        should execute.idempotently
      end
    end

     describe_augeas 'sudo_full_refresh', :lens => 'Sssd', :target => '/etc/sssd/sssd.conf' do
       it "should configure custom sudo full refresh timer" do
         should execute.with_change
         aug_get("target[5]/ldap_sudo_full_refresh_interval").should == '10800'
         should execute.idempotently
       end
     end

     describe_augeas 'sudo_smart_refresh', :lens => 'Sssd', :target => '/etc/sssd/sssd.conf' do
       it "should configure custom sudo smart refresh timer" do
         should execute.with_change
         aug_get("target[5]/ldap_sudo_smart_refresh_interval").should == '600'
         should execute.idempotently
       end
     end

     it "should configure custom sssd default domain suffix" do
       should contain_augeas('default_domain_suffix')
     end

     describe_augeas 'default_domain_suffix', :lens => 'Sssd', :target => '/etc/sssd/sssd.conf' do
       it "should configure custom sssd default domain suffix" do
         should execute.with_change
         aug_get("target[2]/default_domain_suffix").should == 'pixiedust.com'
         should execute.idempotently
       end
     end
  end
end
