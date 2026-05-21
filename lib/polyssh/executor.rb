require "open3"
require "shellwords"

module Polyssh
  module Executor
    def self.build(collector_port, host, command, ssh_options)
      Ractor.new(collector_port, host, command, ssh_options) do |collector_port, host, command, ssh_options|
        Open3.popen3("ssh #{host} #{ssh_options} #{command}") do |stdin, stdout, stderr, wait_thread|
          collector_port.send([:update, host, :pid, wait_thread.pid])
          stdin.close
          loop do
            IO.select([stdout, stderr]).first.each do |io|
              buf = begin
                io.read_nonblock(1024)
              rescue EOFError
                next
              end
              key = io == stdout ? :stdout : :stderr
              collector_port.send([:append, host, key, buf.force_encoding("utf-8")])
            end

            break unless wait_thread.alive?
          end

          collector_port.send([:append, host, :stdout, stdout.read.force_encoding("utf-8")])
          collector_port.send([:append, host, :stderr, stderr.read.force_encoding("utf-8")])

          wait_thread.join
          collector_port.send([:update, host, :status, wait_thread.value.exitstatus])
        end
      end
    end
  end
end
