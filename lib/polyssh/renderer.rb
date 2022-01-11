require "tty-cursor"
require "tty-table"
require "time"

module Polyssh
  module Renderer
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

    def self.build(collector, hosts, command)
      Ractor.new(collector, hosts, command) {|collector, hosts, command|
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
    end
  end
end
