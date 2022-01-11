require "optparse"

module Polyssh
  class CLI
    def self.run(argv)
      new.run(argv)
    end

    def run(argv)
      ssh_options = nil

      OptionParser.new do |o|
        o.on("--ssh-options SSH_OPTIONS") {|s| ssh_options = s }
        o.order!(argv)
      end

      hosts = argv.shift.to_s.split(",")

      if hosts.empty?
        warn "At least one host required. Please specify like `--hosts host1,host2`."
        exit 1
      end

      Polyssh.run(hosts, argv, ssh_options:)
    end
  end
end
