module Utils
  module FileSystem
    class << self
      def root_path
        @root_path ||=
          begin
            path = Pathname.new File.expand_path(Settings[:fs_sync_path])
            unless Dir.exist?(path)
              raise IOError, "`#{path}` does not exist or not a folder"
            end

            path
          end
      end

      def relative_path(full_path)
        path = Pathname.new(full_path).relative_path_from(root_path)
        if path.to_path.include?("./")
          raise ArgumentError, "`#{full_path}` must be a sub-directory of `#{root_path}`"
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
        ignore_checker.match?(path) &&
          (File.directory?(path) ? true : supported_extensions.include?(File.extname(path)))
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

      def supported_extensions
        @supported_extensions ||=
          begin
            supplemental_extensions =
              (Settings[:fs_supplemental_extensions] || [])
                .map { it.start_with?(".") ? it.to_s : "." + it.to_s  }
            (Constants::FileSystem::SUPPORTED_EXTENSIONS + supplemental_extensions).freeze
          end
      end

      def supported_extensions_regex
        @supported_extensions_regex ||=
          %r{\A*\.(?:#{supported_extensions.map { it[1..] }.join("|")})(/|\z)}x.freeze
      end

      def file_checksum(file_path)
        Digest::CRC64NVMe.file(file_path).hexdigest
      end

      def path_checksum(file_path, full_path: true)
        if full_path
          Digest::CRC32c.hexdigest(relative_path(file_path).to_s)
        else
          Digest::CRC32c.hexdigest(file_path.to_s)
        end
      end

      def mime_type(file_path)
        Marcel::MimeType.for(Pathname.new(file_path), extension: File.extname(file_path))
      end

      def filename(file_path)
        File.basename(file_path)
      end
    end
  end
end
