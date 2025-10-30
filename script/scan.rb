#!/usr/bin/env ruby

require "optparse"
require "pathname"

# Default settings
ENV["RAILS_ENV"] ||= "development"

CLI_USAGE_TEMPLATE = "Usage: #{__FILE__} [options]"

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
_ret = parser.parse!

# Load Rails environment
require_relative "../config/environment"

FORCE_POLLING = Utils::Cli.true? ENV["FORCE_POLLING"]
VERBOSE = Utils::Cli.true? ENV["VERBOSE"]

retrieved_files = []

root_path = Utils::FileSystem.root_path.to_path
dir_retrieve_stacks = [ root_path ]
loop do
  break if dir_retrieve_stacks.empty?

  current_path = dir_retrieve_stacks.pop
  Dir["#{current_path}/*"].each do |path|
    unless Utils::FileSystem.allow? path
      next
    end

    if File.directory?(path)
      dir_retrieve_stacks.push(path)
      next
    elsif File.symlink?(path)
      # Ignore symbolic link
      next
    end

    if File.extname(path).in?(Utils::FileSystem.extensions_associations)
      retrieved_files << path
    end
  end
end

puts retrieved_files
