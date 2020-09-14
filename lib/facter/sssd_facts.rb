require 'facter'

begin
  require 'augeas'
  has_augeas = true
rescue
  has_augeas = false
end

Facter.add('sssd_version') do
  setcode do
    Facter::Util::Resolution.exec('sssd --version')
  end
end

Facter.add(:sssd_services) do
  setcode do
    if has_augeas and File.exist? '/etc/sssd/sssd.conf'
      Augeas::open do |aug|
        aug.load
        aug.get("/files/etc/sssd/sssd.conf/target[.='sssd']/services")
      end
    else
      'nss, pam, ssh'
    end
  end
end
