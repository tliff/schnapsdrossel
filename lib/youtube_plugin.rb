require 'open-uri'
require 'yt'

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
      uri = URI(url)
      video_id = nil
      if uri.path == '/watch'
        params = uri.query.split('&').map{|e| e.split('=', 2)}.to_h
        video_id = params['v']
      else
        video_id = uri.path.gsub('/', '')
      end

      video = Yt::Video.new(id: video_id)

      title = video.title
      duration = video.duration
      if duration >= 60*60
        duration = "%.2i:%.2i:%.2i" % [duration  / 3600, (duration/60)%60, duration%60]
      else
        duration = "%.2i:%.2i" % [(duration/60)%60, duration%60]
      end
      "#{title} (#{duration})"
    end

  end

end
