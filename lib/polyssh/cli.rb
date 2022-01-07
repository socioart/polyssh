require "open3"
require "time"
require "tty-cursor"
require "tty-table"
require "shellwords"
require "optparse"

module Polyssh
  class CLI
    class MultilineRenderer
      def initialize
        @prev_lines = 0
      end

      def render
        $stdout.print TTY::Cursor.clear_lines(@prev_lines + 1, :up) if @prev_lines > 0
        @prev_lines = 0
        yield self
      end

      def puts(o = "\n")
        $stdout.puts o
        @prev_lines += o.lines.size
      end
    end

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

      multiline_renderer = MultilineRenderer.new
      headers = %i(host pid status stdout stderr)
      command = argv.shelljoin

      thread_and_data = hosts.map do |host|
        data = {
          host: host,
          pid: nil,
          status: nil,
          stdout: "",
          stderr: "",
        }
        thread = Thread.new do
          Open3.popen3("ssh #{host} #{command}") do |stdin, stdout, stderr, wait_thread|
            data[:pid] = wait_thread.pid
            stdin.close
            loop do
              IO.select([stdout, stderr]).first.each do |io|
                buf = begin
                  io.read_nonblock(1024)
                rescue EOFError
                  next
                end
                (io == stdout ? data[:stdout] : data[:stderr]) << buf.force_encoding("utf-8")
              end
              break unless wait_thread.alive?
            end

            data[:stdout] << stdout.read.force_encoding("utf-8")
            data[:stderr] << stderr.read.force_encoding("utf-8")

            wait_thread.join
            data[:status] = wait_thread.value.exitstatus
          end
        end
        {
          thread: thread,
          data: data,
        }
      end

      renderer = Thread.new {
        loop do
          table = TTY::Table.new(header: headers)
          thread_and_data.each do |h|
            data = h.fetch(:data)
            table << headers.map {|k| data.fetch(k) }
          end

          multiline_renderer.render do |m|
            m.puts "Running `#{command}` on #{hosts.size} hosts."
            m.puts Time.now.iso8601(3)
            m.puts(
              table.render(:unicode, padding: [0, 1], resize: true, multiline: true) {|r|
                r.border.separator = :each_row
              },
            )
          end

          break if thread_and_data.all? {|h| !h.fetch(:thread).alive? }

          sleep 1
        end
      }

      thread_and_data.map {|h| h[:thread].join }

      renderer.join
      puts "Done."
    end
  end
end
