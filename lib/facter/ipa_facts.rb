require 'facter'
require 'resolv'

if File.exist?('/etc/sssd/sssd.conf') && sssd = File.readlines('/etc/sssd/sssd.conf')
  sssd.each do |line|
    case line
      when /^ipa_domain/
        Facter.add("ipa_domain") do
	      has_weight 100
          setcode do
            line.split("=")[1].strip
          end
        end
      when /^ipa_server/
        Facter.add("ipa_server") do
	      has_weight 100
          setcode do
            line.split("=")[1].strip
          end
        end
      when /^auth_provider/
        Facter.add("ipa_enrolled") do
          setcode do
            if line =~ /ipa/
              true
            else
              false
            end
          end
        end
    end
  end
end

# If sssd isn't installed, ipa isn't enrolled
if not File.exist?('/etc/sssd/sssd.conf')
  Facter.add("ipa_enrolled") do
    setcode do
      false
    end
  end
end

# In the event we can't find the records from SSSD, we'll use DNS
if Facter.value(:ipa_server).nil? || Facter.value(:ipa_domain).nil?
  begin
    realm = Resolv::DNS.new.getresource("_kerberos", Resolv::DNS::Resource::IN::TXT).strings.first

    Facter.add("ipa_domain") do
      has_weight 50
      setcode do
        realm.downcase
      end
    end

    Facter.add("ipa_server") do
      has_weight 50
      setcode do
        "_srv_"
      end
    end

  rescue => e
    # do nothing
  end 
end
