Facter.add("is_ipa_server") do
  setcode do
    # Is there a better way?
    if File.exist? "/etc/init.d/ipa"
      "true"
    else
      "false"
    end
  end
end
