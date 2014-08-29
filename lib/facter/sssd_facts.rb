require 'facter'
require 'augeas'

Facter.add('sssd_version') do
  setcode do
    Facter::Util::Resolution.exec('sssd --version')
  end
end

Facter.add(:sssd_services) do
  setcode do
    Augeas::open do |aug|
      aug.load
      aug.get("/files/etc/sssd/sssd.conf/target[.='sssd']/services")
    end
  end
end
