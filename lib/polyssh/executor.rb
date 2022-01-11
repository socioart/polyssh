module Polyssh
  module Executor
    def self.build(collector, host, command)
      Ractor.new(collector, host, command) do |collector, host, command|
        Open3.popen3("ssh #{host} #{command}") do |stdin, stdout, stderr, wait_thread|
          collector.send([:update, host, :pid, wait_thread.pid])
          stdin.close
          loop do
            IO.select([stdout, stderr]).first.each do |io|
              buf = begin
                io.read_nonblock(1024)
              rescue EOFError
                next
              end
              key = io == stdout ? :stdout : :stderr
              collector.send([:append, host, key, buf.force_encoding("utf-8")])
            end

            break unless wait_thread.alive?
          end

          collector.send([:append, host, :stdout, stdout.read.force_encoding("utf-8")])
          collector.send([:append, host, :stderr, stderr.read.force_encoding("utf-8")])

          wait_thread.join
          collector.send([:update, host, :status, wait_thread.value.exitstatus])
        end
      end
    end
  end
end
