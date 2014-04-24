require 'facter'

Facter.add('sssd_version') do
  setcode do
    if Facter::Core::Execution.which('sssd')
      sssd_version = Facter::Core::Execution.exec('sssd --version')
      sssd_version.gsub(/\s+/, "")
    end
  end
end
