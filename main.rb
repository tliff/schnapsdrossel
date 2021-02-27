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
require 'valinfo_plugin.rb'

module Schnapsdrossel
  ALLOWED_HOSTS = [
    'tliff.users.quakenet.org',
    'gix-.users.quakenet.org',
    'Raim-I.users.quakenet.org'
  ].freeze

  access_checker = -> (user) {
    ALLOWED_HOSTS.include?(user.host)
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
        YoutubePlugin,
        ValinfoPlugin
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
      @bot.quit("brb") if access_checker.call(m.user)
    end

    on :channel, /^\.die$/ do |m|
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


