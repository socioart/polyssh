require "polyssh/version"

module Polyssh
  class Error < StandardError; end

  def self.run(hosts, command_and_arguments, ssh_options: "")
    command = command_and_arguments.shelljoin
    collector = Collector.build(hosts)
    executors = hosts.map do |host|
      Executor.build(collector.default_port, host, command, ssh_options)
    end
    renderer = Renderer.build(collector.default_port, hosts, command)

    executors.each(&:join)
    renderer.send([:end])
    renderer.join
    collector.send([:end])
    collector.join

    puts "Done."
  end
end

require "polyssh/cli"
require "polyssh/collector"
require "polyssh/executor"
require "polyssh/renderer"
require "polyssh/patches_for_ractor"
