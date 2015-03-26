require 'cinch'
require 'open-uri'
require 'uri'
require 'twitter'
require 'pp'
require 'yaml'
require 'htmlentities'

$:.unshift File.expand_path( '../lib', __FILE__ )

require 'tumblr_plugin.rb'
require 'twitter_plugin.rb'
require 'spotify_plugin.rb'
require 'youtube_plugin.rb'
require 'definitions_plugin.rb'

module Schnapsdrossel
  
  access_checker = -> (user) {
    user.host == 'tliff.users.quakenet.org' 
  }

  bot = Cinch::Bot.new do
    configure do |c|
      YAML.load(File.read('config/bot.yml')).each do |k,v|
        c.send("#{k}=".to_sym, v)
      end
      c.plugins.plugins = [
        SpotifyPlugin,
        DefinitionsPlugin,
        TumblrPlugin,
        TwitterPlugin,
        YoutubePlugin
      ]
      c.plugins.options = {
        DefinitionsPlugin => {
          access_checker: access_checker
        },
        TumblrPlugin => YAML.load(File.read('config/tumblr.yml')),
        TwitterPlugin => {twitter: YAML.load(File.read('config/twitter.yml')), channel: c.channels.first},
      }
    end

    on :channel, /^\.reload$/ do |m|
      exit 0 if access_checker.call(m.user)
    end
  
    on :channel, /^\.eval / do |m|
      if access_checker.call(m.user)
        m.channel.msg eval(m.message.gsub(/^\.eval /,''))
      end
    end

  end


  bot.start
  
end


