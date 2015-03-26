require 'yaml'

module Schnapsdrossel
  class DefinitionsPlugin
    include Cinch::Plugin

    DEFINITION_FILE = 'definitions.yml'

    def initialize(*args)
      super
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
      if MASTERS.member?(m.user.host)
        @definitions[verb] = action
        File.write(DEFINITION_FILE, @definitions.to_yaml)
      end
    end

  end

end