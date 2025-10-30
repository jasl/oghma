module Constants
  module FileSystem
    # Controlled by the app
    EXTENSIONS_ASSOCIATIONS = {
      # Documents
      ".txt" => :plain,
      ".md" => :plain,
      ".docx" => :word,
      ".pdf" => :pdf,
      # Images
      ".jpeg" => :jpeg,
      ".jpg" => :jpeg,
      ".png" => :png,
      # Videos
      ".mkv" => :video,
      ".mp4" => :video,
    }.freeze

    GLOBAL_IGNORE_PATTERNS = %w[
      *~
      \#*\#
      .#*
      node_modules
      .git
      .svn
      .hg
      .rbx
      .bundle
      .idea
    ].freeze
  end
end
