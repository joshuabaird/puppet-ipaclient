require 'facter'

Facter.add('sssd_version') do
  setcode do
    Facter::Util::Resolution.exec('sssd --version')
  end
end
