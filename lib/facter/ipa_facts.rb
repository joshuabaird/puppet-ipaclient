require 'facter'

if File.exist?('/etc/sssd/sssd.conf') && sssd = File.readlines('/etc/sssd/sssd.conf')
  sssd.each do |line|
    case line
      when /^ipa_domain/
        Facter.add("ipa_domain") do
          setcode do
            line.split("=")[1].strip
          end
        end
      when /^ipa_server/
        Facter.add("ipa_server") do
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
