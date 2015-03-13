require 'cinch'
require 'net/http'
require 'uri'
require 'twitter'
require 'tumblr_client'
require 'socket'
require 'pp'
require 'open-uri'
require 'nokogiri'
require 'htmlentities'

MAX_SIZE = 1024*1024*10
HTTP_REGEX = /(http[s]?:\/\/\S+)/
MASTERS = ['tliff.users.quakenet.org']

require './config.rb'
$urls = []
$done_tweets = []

def check_link url
  puts "checking #{url}"
  if $urls.member?(url)
    puts "Already posted"
    return
  end
  uri = URI(url)
  Net::HTTP.start(uri.host) do |http|
    http.open_timeout = 2
    http.read_timeout = 2
    req = Net::HTTP::Head.new("#{uri.path}#{uri.query ? '?' + uri.query : ''}")
    req = http.request(req)
    if req['content-length'].to_i < MAX_SIZE && (req['content-type'] =~ /^image/ || req['content-type'] =~ /^video\/webm/ )
      Tumblr::Client.new.text('shitmybarsays.tumblr.com', :body => "![Alt text](#{url})", :format => "markdown")
      $urls << url
    end
  end
end

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.quakenet.org"
    c.user = 'schnapsdrossel'
    c.channels = ["#bar"]
    c.nicks = ['schnapsdrossel']
    c.encode ="utf-8"
  end

  on :channel do |m|
    m.message.scan(HTTP_REGEX){|match|
      check_link match.first
    }
  end
  
  on :channel, /^\.reload$/ do |m|
    if MASTERS.member?(m.user.host)
      exit 0
    end
  end
  
  on :channel, /^\.eval / do |m|
    if MASTERS.member?(m.user.host)
      m.channel.msg eval(m.message.gsub(/^\.eval /,''))
    end
  end
  
  on :channel, /spotify(.com?)[:\/]track[:\/](.*)/ do |_, track|
    xml = Nokogiri::XML(open('http://ws.spotify.com/lookup/1/?uri='+track).read)
    xml.remove_namespaces!
    track_name = xml.at_xpath('/track/name').content rescue ''
    artist_name = xml.at_xpath('/track/artist/name').content rescue ''
    m.channel.msg("#{artist_name} - #{track_name}") if !track_name.empty? && !artist_name.empty?
  end

  on :channel, /spotify(.com?)[:\/]album[:\/](.*)/ do |_, track|
    xml = Nokogiri::XML(open('http://ws.spotify.com/lookup/1/?uri='+track).read)
    xml.remove_namespaces!
    track_name = xml.at_xpath('/album/name').content rescue ''
    artist_name = xml.at_xpath('/album/artist/name').content rescue ''
    m.channel.msg("#{artist_name} - #{track_name}") if !track_name.empty? && !artist_name.empty?
  end

  on :connect do |m|
    puts "On connect"
    loop do
      begin
        $client.user do |message|
          if message.is_a? Twitter::Tweet
            if !$done_tweets.member?(message.id)
              $done_tweets << message.id
              puts "Tweet by #{message.user.name}: #{message.text}"
              Channel('#bar').msg "Tweet by @#{message.user.screen_name} (#{message.user.name}): #{HTMLEntities.new.decode message.text}" if message.retweeted_status.is_a?(Twitter::NullObject)
              if !message.retweeted_status.is_a?(Twitter::NullObject) && !$done_tweets.member?(message.retweeted_status.id)
                $done_tweets << message.retweeted_status.id
                Channel('#bar').msg "Tweet by @#{message.user.screen_name} (#{message.user.name}): RT #{HTMLEntities.new.decode message.retweeted_status.user.screen_name} #{message.retweeted_status.text}" 
              end
            end
          end
        end
      rescue
        next
      end
    end
  end
end

bot.start


