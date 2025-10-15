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

FORCE_POLLING = Constants::Cli.toggle_true? ENV["FORCE_POLLING"]
VERBOSE = Constants::Cli.toggle_true? ENV["VERBOSE"]

require "listen"

if VERBOSE
  Listen.logger = ActiveSupport::Logger.new(STDOUT)
end

listener = Listen.to(
  watched_path,
  force_polling: FORCE_POLLING,
  only: Constants::FileSystem::SUPPORTED_EXTENSIONS_PATTERN,
  ignore: [ Constants::FileSystem::IGNORED_FILES_PATTERN, Constants::FileSystem::IGNORED_EXTENSIONS_PATTERN ],
  ignore!: []
) do |modified, added, removed|
  puts(modified: modified, added: added, removed: removed)
end

puts "Environment: #{ENV["RAILS_ENV"]}"
puts "Watching: #{watched_path}"
puts "Watcher backend: #{listener.instance_variable_get(:@backend).instance_variable_get(:@adapter).class}"

listener.start
sleep
