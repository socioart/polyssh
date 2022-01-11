require "open3"
require "shellwords"
require "optparse"

module Polyssh
  class CLI
    def self.run(argv)
      new.run(argv)
    end

    def run(argv)
      ssh_options = nil

      OptionParser.new do |o|
        o.on("--ssh-options SSH_OPTIONS") {|s| ssh_options = s}
        o.order!(argv)
      end

      hosts = argv.shift.to_s.split(",")

      if hosts.empty?
        warn "At least one host required. Please specify like `--hosts host1,host2`."
        exit 1
      end

      command = argv.shelljoin

      collector = Collector.build(hosts)
      executors = hosts.map do |host|
        Executor.build(collector, host, command)
      end
      renderer = Renderer.build(collector, hosts, command)

      executors.each(&:take)
      renderer.send([:end])
      renderer.take
      collector.send([:end])
      collector.take

      puts "Done."
    end
  end
end
