require "socket"
require "timeout"

module Schnapsdrossel
  class ValinfoPlugin
    include Cinch::Plugin

    SERVER = 'gaming.tliff.de'

    match /\!valinfo/, use_prefix: false

    def execute(m)
      client = UDPSocket.new
      query_string = [(256**4-1), "TSource Engine Query", 0].pack("LA*C")
      client.send(query_string, 0, SERVER, 2457)
      begin
        Timeout::timeout(1) do
          response = client.recv(1024)
          name, name, game, playercount, strange_version, real_version = response.unpack("x6Z*Z*Z*L>x6Z*x11Z*x8")
          m.channel.msg("#{name} (#{IPSocket.getaddress(SERVER)}:2456) is online running version #{real_version}. #{playercount} viking#{playercount != 1 ? "s" : ""} online.")
        end
      rescue
        m.channel.msg("Server seems to be down :(")
      end
    end
  end
end
