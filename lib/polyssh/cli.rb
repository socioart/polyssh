require "open3"
require "time"
require "tty-cursor"
require "tty-table"
require "shellwords"
require "optparse"

# Patches for using ractor
def deep_freeze(o)
  case o
  when Array
    o.each {|e| deep_freeze(e) }
  when Hash
    o.each {|k, v|
      k.freeze
      deep_freeze(v)
    }
  end
  o.freeze
end

deep_freeze(TTY::Table::Renderer::RENDERER_MAPPER)
Ractor.make_shareable(TTY::Table::Border::Unicode.characters)

require "tty-color"
module TTY
  module Color
    ENV = deep_freeze(ENV.to_h)

    def output
      $stderr
    end
  end
end

require "pastel"
Ractor.make_shareable(Pastel::DecoratorChain.empty)
module Pastel
  ENV = deep_freeze(ENV.to_h)
end

require "unicode/display_width"
deep_freeze(Unicode::DisplayWidth::INDEX)

require "unicode_utils"
deep_freeze(UnicodeUtils::GRAPHEME_CLUSTER_BREAK_MAP)

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

      command = argv.shelljoin

      collector = Ractor.new(hosts) do |hosts|
        data = hosts.each_with_object({}) {|host, h|
          h[host] = {
            host: host,
            pid: nil,
            status: nil,
            stdout: "",
            stderr: "",
          }
        }

        loop do
          case Ractor.recv
          in [:data, renderer]
            renderer.send([:data, data])
          in [:update, host, key, value]
            data[host][key] = value
          in [:append, host, key, value]
            data[host][key] << value
          in [:end]
            break
          end
        end
      end

      executors = hosts.map do |host|
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

      renderer = Ractor.new(collector, hosts, command) {|collector, hosts, command|
        multiline_renderer = MultilineRenderer.new
        headers = %i(host pid status stdout stderr)
        break_after_update = false

        loop do
          collector.send([:data, Ractor.current])
          case Ractor.recv
          in [:data, data]
            table = TTY::Table.new(header: headers)
            data.each do |_host, d|
              table << headers.map {|k| d.fetch(k) }
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

            break if break_after_update

            sleep 1
          in [:end]
            break_after_update = true
          end
        end
      }

      executors.each(&:take)
      renderer.send([:end])
      renderer.take
      collector.send([:end])
      collector.take

      puts "Done."
    end
  end
end
