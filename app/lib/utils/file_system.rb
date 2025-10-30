module Utils
  module FileSystem
    class << self
      def root_path
        @root_path ||=
          begin
            path = Pathname.new File.expand_path(Settings.fs_sync_path)
            unless Dir.exist?(path)
              raise IOError, "`#{path}` does not exist or not a folder"
            end

            path
          end
      end

      def relative_path(requested_path, skip_exist_check: false)
        path = root_path.join(requested_path)
        unless skip_exist_check || File.exist?(path)
          raise ArgumentError, "`#{requested_path}` does not exist"
        end

        path = path.relative_path_from(root_path).to_path
        if path.start_with? "."
          path[0] = "/"
        end

        path
      end

      def ignore_checker
        @ignore_checker ||=
          begin
            customized_patterns = Settings[:fs_ignore_patterns] || []
            merged_patterns = (Constants::FileSystem::GLOBAL_IGNORE_PATTERNS + customized_patterns).uniq
            PathList.ignore(merged_patterns, root: root_path)
          end
      end

      def allow?(path)
        ignore_checker.match?(path)
      end

      def ignore?(path)
        !ignore_checker.match?(path)
      end

      def ignore_regex_patterns
        @ignore_regex_patterns ||=
          begin
            ignore_checker
              .instance_variable_get(:@matcher)
              .instance_variable_get(:@matchers)
              .select { it.class == PathList::Matcher::PathRegexp::CaseInsensitive && it.polarity == :ignore }
              .map { it.instance_variable_get(:@regexp) }
          end
      end

      def extensions_associations
        @extensions_associations ||=
          begin
            customized_associations = (Settings[:fs_extensions_associations].to_hash || {})
            customized_associations.transform_keys! { it.start_with?(".") ? it.to_s : "." + it.to_s }
            customized_associations.transform_values!(&:to_sym)
            Constants::FileSystem::EXTENSIONS_ASSOCIATIONS.merge(customized_associations).freeze
          end
      end

      def supported_extensions
        @supported_extensions ||= extensions_associations.keys.freeze
      end

      def supported_extensions_regex
        @supported_extensions_regex ||=
          %r{\A*\.(?:#{supported_extensions.map { it[1..] }.join("|")})(/|\z)}x.freeze
      end
    end
  end
end
