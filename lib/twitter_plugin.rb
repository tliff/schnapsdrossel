require 'yaml'
require 'pp'

module Schnapsdrossel
  class TwitterPlugin
    include Cinch::Plugin

    listen_to :connect, method: :setup_listener

    #match /define\s+(\w+)\s+(.*)/, prefix: '.', method: :define
    #match /\!(\w+)\s*(.*)/, use_prefix: false

    def execute

    end

    def setup_listener(_)
      puts "On connect"
      done_tweets = []
      Thread.new do
        loop do
          begin
            client = Twitter::Streaming::Client.new do |conf|
              config[:twitter].each do |k,v|
                conf.send("#{k}=".to_sym, v)
              end
            end
            client.user do |message|
              if message.is_a? Twitter::Tweet
                if !done_tweets.member?(message.id)
                  done_tweets << message.id
                  puts "Tweet by #{message.user.name}: #{message.text}"
                  Channel(config[:channel]).msg "Tweet by @#{message.user.screen_name} (#{message.user.name}): #{HTMLEntities.new.decode message.text}".strip.gsub(/\n+/, ' | ') if message.retweeted_status.is_a?(Twitter::NullObject)
                  if !message.retweeted_status.is_a?(Twitter::NullObject) && !done_tweets.member?(message.retweeted_status.id)
                    done_tweets << message.retweeted_status.id
                    Channel(config[:channel]).msg "Tweet by @#{message.user.screen_name} (#{message.user.name}): RT #{HTMLEntities.new.decode message.retweeted_status.user.screen_name} #{message.retweeted_status.text}".strip.gsub(/\n+/, ' | ')
                  end
                end
              end
            end
          rescue StandardError => e
            Channel(config[:channel]).msg e.to_s
          end
        end
      end
    end

  end

end

#on :channel, /http[s]?:\/\/twitter.com\/.*\/status\/(\d+)/ do |m, tweetid|
#  tweet = $client.status(tweetid.to_i)
#  if !tweet.is_a?(Twitter::NullObject)
#    m.channel.msg "Tweet by @#{tweet.user.screen_name} (#{tweet.user.name}): #{HTMLEntities.new.decode tweet.text}".strip.gsub(/\n/, ' | ')
#  end
#end
#on :connect do |m|

#end
