module Utils
  module Cli
    class << self
      FALSE_VALUES = [
        nil,
        false, 0,
        "0", :"0",
        "f", :f,
        "F", :F,
        "false", :false,
        "FALSE", :FALSE,
        "off", :off,
        "OFF", :OFF,
      ].to_set.freeze

      def true?(v)
        !FALSE_VALUES.include?(v)
      end
    end
  end
end
