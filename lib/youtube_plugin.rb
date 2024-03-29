require 'open-uri'
require 'nokogiri'

module Schnapsdrossel
  class YoutubePlugin
    include Cinch::Plugin
    REGEX =  %r!(?<=\A|\s)(https?://\S*youtu[\.]?be\S+)(?=\z|\s)!i
    match REGEX, use_prefix: false

    def execute(m, url)
      urls = m.message.scan(REGEX)
      m.channel.msg("Youtube: #{urls.map{|url| video_data(url.first)}.join(' | ')}")
    end

    def video_data(url)
      data = Nokogiri::HTML(URI.open(url).read)
      title = data.css('meta[property="og:title"]').first['content']
      duration = nil
      data.css('[itemprop="duration"]').first['content'].gsub(/PT(\d+)M(\d+)S/) do |_|
        minutes, seconds = $1.to_i, $2.to_i
        if minutes >= 60
          duration = "%.2i:%.2i:%.2i" % [minutes / 60, minutes % 60, seconds]
        else
          duration = "%.2i:%.2i" % [minutes, seconds]
        end
      end
      "#{title} (#{duration})"
    end

  end

end
