#!/usr/bin/env ruby
# frozen_string_literal: true

require "optparse"
require "pathname"

# Default settings
ENV["RAILS_ENV"] ||= "development"

CLI_USAGE_TEMPLATE = "Usage: #{__FILE__} PATH [options]"
TRUE_WORDS = %w[1 t true yes]

parser = OptionParser.new
parser.on(
  "-e", "--environment=ENVIRONMENT",
  "The environment to run `watch` in (e.g. test / development / production)."
) do |v|
  ENV["RAILS_ENV"] = v
end
parser.on(
  "--verbose",
  "Print extended logs"
) do
  ENV["VERBOSE"] = "1"
end
ret = parser.parse!

watched_path = ret.first&.strip
if watched_path.nil? || watched_path.empty?
  puts CLI_USAGE_TEMPLATE
  Process.exit! 1
end
watched_path = Pathname.new File.expand_path(watched_path)
unless Dir.exist?(watched_path)
  puts "#{watched_path} does not exist or not a directory!"
  Process.exit! 1
end
watched_path = watched_path.to_s

# Load Rails environment
require_relative "../config/environment"

FORCE_POLLING = ENV["FORCE_POLLING"].in? TRUE_WORDS
VERBOSE = ENV["VERBOSE"].in? TRUE_WORDS

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

retrieved_files = []

dir_retrieve_stacks = [ watched_path ]
loop do
  break if dir_retrieve_stacks.empty?

  current_path = dir_retrieve_stacks.pop
  Dir["#{current_path}/*"].each do |path|
    if File.directory?(path)
      dir_retrieve_stacks.push(path)
      next
    elsif File.symlink?(path)
      # Ignore symbolic link
      next
    end

    if File.extname(path).in?(SUPPORTED_EXTENSIONS)
      retrieved_files << path
    end
  end
end

puts retrieved_files
