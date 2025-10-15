#!/usr/bin/env ruby
# frozen_string_literal: true

require "optparse"
require "pathname"

# Default settings
ENV["RAILS_ENV"] ||= "development"

CLI_USAGE_TEMPLATE = "Usage: #{__FILE__} PATH [options]"

parser = OptionParser.new
parser.on(
  "-e", "--environment=ENVIRONMENT",
  "The environment to run `scan` in (e.g. test / development / production)."
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

FORCE_POLLING = Constants::Cli.toggle_true? ENV["FORCE_POLLING"]
VERBOSE = Constants::Cli.toggle_true? ENV["VERBOSE"]

retrieved_files = []

dir_retrieve_stacks = [ watched_path ]
loop do
  break if dir_retrieve_stacks.empty?

  current_path = dir_retrieve_stacks.pop
  Dir["#{current_path}/*"].each do |path|
    if File.basename(path).in? Constants::FileSystem::IGNORED_FILES
      next
    end

    if File.directory?(path)
      dir_retrieve_stacks.push(path)
      next
    elsif File.symlink?(path)
      # Ignore symbolic link
      next
    end

    if File.extname(path).in?(Constants::FileSystem::SUPPORTED_EXTENSIONS)
      retrieved_files << path
    end
  end
end

puts retrieved_files
