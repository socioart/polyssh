require "polyssh/version"

module Polyssh
  class Error < StandardError; end

  def self.run(hosts, command_and_arguments, ssh_options: "")
    command = command_and_arguments.shelljoin
    collector = Collector.build(hosts)
    executors = hosts.map do |host|
      Executor.build(collector, host, command, ssh_options)
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

require "polyssh/cli"
require "polyssh/collector"
require "polyssh/executor"
require "polyssh/renderer"
require "polyssh/patches_for_ractor"
