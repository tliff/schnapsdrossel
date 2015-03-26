require 'nokogiri'

module Schnapsdrossel
  class SpotifyPlugin
    include Cinch::Plugin
  
    match /spotify(.com?)[:\/](track|album)[:\/](.*)/, use_prefix: false
  
    def execute(m, _, type, identifier)
      puts config[:tumblr]
      xml = Nokogiri::XML(open("http://ws.spotify.com/lookup/1/?uri=spotify:#{type}:#{identifier}").read)
      xml.remove_namespaces!
      track_name = xml.at_xpath("/#{type}/name").content rescue ''
      artist_name = xml.at_xpath("/#{type}/artist/name").content rescue ''
      m.channel.msg("#{artist_name} - #{track_name}") if !track_name.empty? && !artist_name.empty?
    end
  end
end