# frozen_string_literal: true

module Constants
  module FileSystem
    # Controlled by the app
    SUPPORTED_EXTENSIONS = [
      # Documents
      ".md",
      ".docx",
      ".pdf",
      # Images
      ".jpeg",
      ".jpg",
      ".png",
      # Videos
      # TEST
      ".rb",
      ".js"
    ].freeze

    SUPPORTED_EXTENSIONS_PATTERN = %r{\A*\.(?:#{SUPPORTED_EXTENSIONS.map { it[1..] }.join("|")})(/|\z)}x.freeze

    # TODO: Configurable by user
    IGNORED_FILES = %w[
      node_modules
      .git
      .svn
      .hg
      .rbx
      .bundle
    ].freeze

    IGNORED_FILES_PATTERN = %r{\A(?:
      # Emacs temp files
      | \#.+\#
      # Ignore all files start with .
      #{IGNORED_FILES.any? ? "|" + IGNORED_FILES.join("|") : ""}
    )(/|\z)}x.freeze

    # Controlled by the app
    IGNORED_EXTENSIONS_PATTERN = %r{(?:
      # Kate's tmp and swp files
      \..*\d+\.new
      | \.kate-swp

      # Gedit tmp files
      | \.goutputstream-.{6}

      # Intellij files
      | ___jb_bak___
      | ___jb_old___

      # Vim swap files and write test
      | \.sw[px]
      | \.swpx
      | ^4913

      # Sed temporary files - but without actual words, like 'sedatives'
      | \Ased(?:
          [a-zA-Z0-9]{0}[A-Z]{1}[a-zA-Z0-9]{5} |
          [a-zA-Z0-9]{1}[A-Z]{1}[a-zA-Z0-9]{4} |
          [a-zA-Z0-9]{2}[A-Z]{1}[a-zA-Z0-9]{3} |
          [a-zA-Z0-9]{3}[A-Z]{1}[a-zA-Z0-9]{2} |
          [a-zA-Z0-9]{4}[A-Z]{1}[a-zA-Z0-9]{1} |
          [a-zA-Z0-9]{5}[A-Z]{1}[a-zA-Z0-9]{0}
         )

      # Mutagen sync temporary files
      | \.mutagen-temporary.*

      # other files
      | \.DS_Store
      | \.tmp
      | ~
    )\z}x.freeze
  end
end
