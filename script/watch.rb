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
parser.on(
  "--force-polling",
  "Force to use polling mode (slow but max compatibility)"
) do
  ENV["FORCE_POLLING"] = "1"
end
ret = parser.parse!

watched_path =
  begin
    path = ret.first&.strip
    if path.nil? || path.empty?
      puts CLI_USAGE_TEMPLATE
      Process.exit! 1
      return
    end

    path = Pathname.new File.expand_path(path)
    unless Dir.exist?(path)
      puts "#{path} does not exist or not a directory!"
      Process.exit! 1
      return
    end

    path.to_s
  end

# Load Rails environment
require_relative "../config/environment"

FORCE_POLLING = ENV["FORCE_POLLING"].in? TRUE_WORDS
VERBOSE = ENV["VERBOSE"].in? TRUE_WORDS

# Controlled by the app
SUPPORTED_EXTENSIONS = [
  # Documents
  "md",
  "docx",
  "pdf",
  # Images
  "jpeg",
  "jpg",
  "png"
  # Videos
].freeze

SUPPORTED_EXTENSIONS_PATTERN = %r{\A*\.(?:#{SUPPORTED_EXTENSIONS.join("|")})(/|\z)}x.freeze

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

require "listen"

if VERBOSE
  Listen.logger = ActiveSupport::Logger.new(STDOUT)
end

listener = Listen.to(
  watched_path,
  force_polling: FORCE_POLLING,
  only: SUPPORTED_EXTENSIONS_PATTERN,
  ignore: [ IGNORED_FILES_PATTERN, IGNORED_EXTENSIONS_PATTERN ],
  ignore!: []
) do |modified, added, removed|
  puts(modified: modified, added: added, removed: removed)
end

puts "Environment: #{ENV["RAILS_ENV"]}"
puts "Watching: #{watched_path}"
puts "Watcher backend: #{listener.instance_variable_get(:@backend).instance_variable_get(:@adapter).class}"

listener.start
sleep
