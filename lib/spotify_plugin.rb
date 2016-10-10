require 'json'

module Schnapsdrossel
  class SpotifyPlugin
    include Cinch::Plugin

    match /spotify(\.com)?[:\/](track|album)[:\/](.*)/, use_prefix: false

    def execute(m, _, type, identifier)
      doc = JSON.parse(open("https://api.spotify.com/v1/#{type}s/#{identifier}").read)
      artist = doc['artists'].map{|artist| artist['name']}.join(", ")
      title = doc['name']
      m.channel.msg("#{artist} — #{title}") if !title.empty? && !artist.empty?
    end

  end
end
