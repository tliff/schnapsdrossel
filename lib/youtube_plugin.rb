require 'open-uri'
require 'nokogiri'

module Schnapsdrossel
  class YoutubePlugin
    include Cinch::Plugin
  
    match %r!(?:\A|\s)(https?://\S*youtu[\.]?be\S+)(?:\z|\s)!i, use_prefix: false
    
    def execute(m, url)
      title = Nokogiri::HTML(open(url)).title.gsub(/ - YouTube$/, '')
      m.channel.msg("YouTube: #{title}")
    end

  end

end
