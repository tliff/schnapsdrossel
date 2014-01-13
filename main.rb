require 'cinch'
require 'net/http'
require 'uri'
require 'twitter'
require 'tumblr_client'
require 'socket'
require 'cidr'
require 'pp'

MAX_SIZE = 1024*1024*10
YOUTUBE_URLS = ['youtube.com', 'youtu.be']
HTTP_REGEX = /(http:\/\/\S+)/
VALID_SOURCES = NetAddr::CIDR.create('192.30.252.0/22')



$urls = []

require './config.rb'

def check_link url
  puts "checking #{url}"
  if $urls.member?(url)
    puts "Already posted"
    return
  end
  uri = URI(url)
  if YOUTUBE_URLS.member?(uri.host)
    puts "Youtube link: #{url}"    
  else 
    Net::HTTP.start(uri.host) do |http|
      http.open_timeout = 2
      http.read_timeout = 2
      req = Net::HTTP::Head.new("#{uri.path}#{uri.query ? '?' + uri.query : ''}")
      req = http.request(req)
      if req['content-length'].to_i < MAX_SIZE && req['content-type'] =~ /^image/
        puts "#{url} matched IMAGE"
        t = Tumblr::Client.new
        pp t
        
        if r = t.text('shitmybarsays.tumblr.com', :body => "![Alt text](#{url})", :format => "markdown")
          $urls << url
          puts "SUCCESS! -- #{r}"
        else
          puts "FAIL!!!!"
        end
      end
    end
  end
end

def check_urls 
#  c = Tumblr::Client.new
#  offset = 0
#  while (posts = c.posts("shitmybarsays.tumblr.com", :offset => offset)['posts') && !posts.empty?
#  	$urls += posts.map{|e| 
 #     m = /(http:\/\/\S+)/.match e['body']
 #     m ? m[1].chomp('"') : nil
 ##   }.compact
 #   offset += 20
 # end
 # pp $urls
end

def check_webhook
  Thread.new do 
    fam, port, *addr = TCPServer.new(8082).accept.getpeername.unpack('nnC4')
    if valid_sources.contains?(addr.join)
      exit
    end
end



bot = Cinch::Bot.new do
  configure do |c|
    c.server = "underworld.no.quakenet.org"
    c.user = 'schnapsdrossel'
    c.channels = ["#bar"]
    c.nicks = ['schnapsdrossel']
  end

  on :channel do |m|
    if match = HTTP_REGEX.match(m.message) 
      check_link match[1]
    end
  end

  on :connect do |m|
    puts "On connect"
    $client.user do |message|
      if message.is_a? Twitter::Tweet
        puts "Tweet by #{message.user.name}: #{message.text}"
        Channel('#bar').msg "Tweet by #{message.user.name} (#{message.user.screen_name}): #{message.text}"
      end
    end
  end
end

check_urls
check_webhook
bot.start


