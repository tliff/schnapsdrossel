require 'cinch'
require 'open-uri'
require 'uri'
require 'pp'
require 'yaml'
require 'htmlentities'
require 'logger'

$:.unshift File.expand_path( '../lib', __FILE__ )

require 'spotify_plugin.rb'
require 'youtube_plugin.rb'
require 'definitions_plugin.rb'
require 'valinfo_plugin.rb'

module Cinch
  module Utilities
    # @since 2.0.0
    # @api private
    module Encoding
      def self.encode_incoming(string, encoding)
        string = string.dup
        if encoding == :irc
          # If incoming text is valid UTF-8, it will be interpreted as
          # such. If it fails validation, a CP1252 -&gt; UTF-8 conversion
          # is performed. This allows you to see non-ASCII from mIRC
          # users (non-UTF-8) and other users sending you UTF-8.
          #
          # (from http://xchat.org/encoding/#hybrid)
          string.force_encoding("UTF-8")
          if !string.valid_encoding?
            string.force_encoding("CP1252").encode!("UTF-8", {:invalid => :replace, :undef => :replace})
          end
        else
          string.force_encoding(encoding).encode!({:invalid => :replace, :undef => :replace})
          string = string.chars.select { |c| c.valid_encoding? }.join
        end

        return string
      end

      def self.encode_outgoing(string, encoding)
        string = string.dup
        if encoding == :irc
          encoding = "UTF-8"
        end
        return string.encode!(encoding).force_encoding("ASCII-8BIT")
      end
    end
  end
end


class CinchLogger 
  def method_missing(name, *arg)
    pp arg
  end


end

module Schnapsdrossel
  ALLOWED_HOSTS = [
    'tliff.users.quakenet.org',
    'gix-.users.quakenet.org',
    'Raim-I.users.quakenet.org'
  ].freeze

  access_checker = -> (user) {
    ALLOWED_HOSTS.include?(user.host)
  }

  bot = Cinch::Bot.new do |bot|
    configure do |c|
      YAML.load(File.read('config/bot.yml')).each do |k,v|
        c.send("#{k}=".to_sym, v)
      end
      
      c.plugins.plugins = [
        SpotifyPlugin,
        DefinitionsPlugin,
        YoutubePlugin,
        ValinfoPlugin
      ]
      c.plugins.options = {
        DefinitionsPlugin => {
          access_checker: access_checker
        },
      }
    end
    bot.loggers = CinchLogger.new



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


