module Polyssh
  module Collector
    def self.build(hosts)
      Ractor.new(hosts) do |hosts|
        data = hosts.each_with_object({}) {|host, h|
          h[host] = {
            host:,
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
    end
  end
end
