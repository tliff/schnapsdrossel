require 'net/http'
require 'tumblr_client'

module Schnapsdrossel
  class TumblrPlugin
    include Cinch::Plugin
    MAX_SIZE = 1024 * 1024 * 10

    match %r{(http[s]?://\S+)}, use_prefix: false

    def initialize
      @urls = []
    end

    def execute(m, url)
      unless @urls.member?(url)
        uri = URI(url)
        Net::HTTP.start(uri.host) do |http|
          http.open_timeout = 2
          http.read_timeout = 2
          req = Net::HTTP::Head.new("#{uri.path}#{uri.query ? '?' + uri.query : ''}")
          req = http.request(req)
          if req['content-length'].to_i < MAX_SIZE && (req['content-type'] =~ /^image/ || req['content-type'] =~ /^video\/webm/ )
            Tumblr::Client.new.text('shitmybarsays.tumblr.com', :body => "![Alt text](#{url})", :format => "markdown")
            @urls << url
          end
        end
      end
    end

  end

end