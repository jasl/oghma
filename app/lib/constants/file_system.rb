module Constants
  module FileSystem
    SUPPORTED_EXTENSIONS = [
      # Plain texts
      ".txt",
      ".md",
      # Documents
      ".docx",
      ".pdf",
      # Images
      ".jpeg",
      ".jpg",
      ".png",
      # Videos
      ".mkv",
      ".mp4",
    ].freeze

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
