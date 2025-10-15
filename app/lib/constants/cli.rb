# frozen_string_literal: true

module Constants
  module Cli
    TRUE_WORDS = %w[1 t true yes]

    class << self
      def toggle_true?(v)
        TRUE_WORDS.include?(v)
      end
    end
  end
end
