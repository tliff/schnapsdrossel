require 'open-uri'
require 'yt'

module Schnapsdrossel
  class YoutubePlugin
    include Cinch::Plugin
    REGEX =  %r!(?<=\A|\s)(https?://\S*youtu[\.]?be\S+)(?=\z|\s)!i
    match REGEX, use_prefix: false
    
    DESCRIPTION_LENGTH = 100

    def execute(m, url)
      urls = m.message.scan(REGEX)
      m.channel.msg("Youtube: #{urls.map{|url| process_url(url.first)}.join(' | ')}")
    end

    def process_url(url)
      uri = URI(url)
      
      # Channel URL detection (format: youtube.com/@channelname or youtube.com/c/channelname)
      if uri.path.start_with?('/@') || uri.path.start_with?('/c/')
        return channel_data(url)
      end
      
      # Regular video processing
      video_data(url)
    end

    def channel_data(url)
      uri = URI(url)
      channel_handle = uri.path.gsub(/\A\/(@|c\/)/, '')
      
      begin
        channel = Yt::Channel.new(id: channel_handle)
        title = channel.title
        description = channel.description.to_s
        truncated_description = description.length > DESCRIPTION_LENGTH ? 
                               "#{description[0...DESCRIPTION_LENGTH]}..." : 
                               description
        
        "Channel: #{title} - #{truncated_description}"
      rescue => e
        "Invalid YouTube channel: #{e.message}"
      end
    end

    def video_data(url)
      uri = URI(url)
      video_id = nil
      if uri.path == '/watch'
        params = uri.query.split('&').map{|e| e.split('=', 2)}.to_h
        video_id = params['v']
      elsif uri.path.start_with?('/shorts/')
        video_id = uri.path.delete_prefix('/shorts/')
      elsif uri.path.start_with?('/live/')
        video_id = uri.path.delete_prefix('/live/')       
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
