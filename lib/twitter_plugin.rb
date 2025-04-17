require 'open-uri'
require 'nokogiri'

module Schnapsdrossel
  class TwitterPlugin
    include Cinch::Plugin
    REGEX =  %r!(?<=\A|\s)(https?://(?:www\.)?(?:x|twitter).com/\S+)(?=\z|\s)!i
    match REGEX, use_prefix: false

    def execute(m, url)
      urls = m.message.scan(REGEX).flatten
      m.channel.msg("Nitter: #{urls.map{|url| url.gsub(%r!(?:www\.)?(?:x|twitter).com/!, 'twiiit.com/')}.join(' | ')}")
    end

  end

end
