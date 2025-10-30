# frozen_string_literal: true

require 'strscan'

class PathList
  class PatternParser
    class Gitignore
      # @api private
      class RuleScanner < ::StringScanner
        # @return [Boolean]
        def character_class_end?
          skip(/\]/)
        end

        # @return [Boolean]
        def character_class_start?
          skip(/\[/)
        end

        # @return [Boolean]
        def character_class_negation?
          skip(/\^|!/)
        end

        # @return [Boolean]
        def slash?
          skip(%r{/})
        end

        # @return [String, nil]
        def root_end
          matched if scan(%r{/\s*\z})
        end

        # @return [String, nil]
        def root
          matched if scan(%r{/})
        end

        # @return [String, nil]
        def home_slash_end
          self[1] if scan(%r{(~[^/]*)/\s*\z})
        end

        # @return [String, nil]
        def home_slash_or_end
          self[1] if scan(%r{(~[^/]*)(?:/|\s*\z)})
        end

        # @return [Boolean]
        def dot_slash_or_end?
          skip(%r{\.(?:/|\s*\z)})
        end

        # @return [Boolean]
        def dot_slash_end?
          skip(%r{\./\s*\z})
        end

        # @return [Boolean]
        def dot_dot_slash_end?
          skip(%r{\.\./\s*\z})
        end

        # @return [Boolean]
        def dot_dot_slash_or_end?
          skip(%r{\.\.(?:/|\s*\z)})
        end

        # @return [Boolean]
        def slash_end?
          skip(%r{/\s*\z})
        end

        # @return [Boolean]
        def escape?
          skip(/\\/)
        end

        # @return [Boolean]
        def star_star_slash_end?
          skip(%r{\*{2,}/\s*\z})
        end

        # @return [Boolean]
        def star_star_slash_slash?
          skip(%r{\*{2,}//})
        end

        # @return [Boolean]
        def slash_slash?
          skip(%r{/{2}})
        end

        # @return [Boolean]
        def star_star_slash?
          skip(%r{\*{2,}/})
        end

        # @return [Boolean]
        def slash_star_star_end?
          skip(%r{/\*{2,}\s*\z})
        end

        # @return [Boolean]
        def star?
          skip(/\*/)
        end

        # @return [String, nil]
        def next_character
          matched if scan(/./)
        end

        # @return [Boolean]
        def question_mark?
          skip(/\?/)
        end

        # @return [String, nil]
        def character_class_literal
          matched if scan(/[^\]\\][^\]\\-]*(?!-)/)
        end

        # @return [String, nil]
        def character_class_range_start
          matched.delete_prefix('\\') if scan(/(\\.|[^\\\]])(?=-(\\.|[^\\\]]))/)
        end

        # @return [String, nil]
        def character_class_range_end
          # we already confirmed this was going to match
          # with the lookahead in character_class_range_start
          skip(/-/)
          scan(/(\\.|[^\\\]])/)
          matched.delete_prefix('\\')
        end

        # @return [String, nil]
        def literal
          matched if scan(%r{[^*/?\[\\\s]+})
        end

        # @return [String, nil]
        def significant_whitespace
          matched if scan(/\s+(?!\s|\z)/)
        end

        # @return [Boolean]
        def exclamation_mark?
          skip(/!/)
        end

        # @return [Boolean]
        def hash?
          skip(/#/)
        end
      end
    end
  end
end
