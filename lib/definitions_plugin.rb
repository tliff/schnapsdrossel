require 'yaml'

module Schnapsdrossel
  class DefinitionsPlugin
    include Cinch::Plugin

    DEFINITION_FILE = 'definitions.yml'

    def initialize(*args)
      super
      @access_checker = config[:access_checker] || lambda { false }
      @definitions = {}
      if File.exist?(DEFINITION_FILE)
        @definitions = YAML.load(File.open(DEFINITION_FILE))
      end
    end

    match /define\s+(\w+)\s+(.*)/, prefix: '.', method: :define
    match /\!(\w+)\s*(.*)/, use_prefix: false

    def execute(m, verb, arguments)
      if definition = @definitions[verb]
        m.channel.msg("#{definition} #{arguments.lstrip}")
      end
    end 

    def define(m, verb, action)
      if @access_checker.call(m.user)
        @definitions[verb] = action
        File.write(DEFINITION_FILE, @definitions.to_yaml)
        m.channel.msg("#{verb} updated")
      end
    end

  end

end
