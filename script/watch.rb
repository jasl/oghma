#!/usr/bin/env ruby

require "optparse"
require "pathname"

# Default settings
ENV["RAILS_ENV"] ||= "development"

CLI_USAGE_TEMPLATE = "Usage: #{__FILE__} [options]"

parser = OptionParser.new
parser.on(
  "-e", "--environment=ENVIRONMENT",
  "The environment to run `watch` in (e.g. test / development / production)."
) do |v|
  ENV["RAILS_ENV"] = v
end
parser.on(
  "--dry-run",
  "Dry run"
) do
  ENV["DRY_RUN"] = "1"
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
_ret = parser.parse!

# Load Rails environment
require_relative "../config/environment"

FORCE_POLLING = Utils::Cli.true? ENV["FORCE_POLLING"]
DRY_RUN = Utils::Cli.true? ENV["DRY_RUN"]
VERBOSE = Utils::Cli.true? ENV["VERBOSE"]

require "listen"

if VERBOSE
  Listen.logger = ActiveSupport::Logger.new(STDOUT)
end

root_path = Utils::FileSystem.root_path.to_path
listener = Listen.to(
  root_path,
  force_polling: FORCE_POLLING,
  only: Utils::FileSystem.supported_extensions_regex,
  ignore: Utils::FileSystem.ignore_regex_patterns,
  ignore!: []
) do |modified, added, removed|
  added = added.select { Utils::FileSystem.allow?(it) }
  if added.any?
    puts "Added: #{added}"
    jobs = added.map { IndexFileJob.new(it) }
    ActiveJob.perform_all_later(jobs) unless DRY_RUN
  end

  removed = removed.select { Utils::FileSystem.allow?(it) }
  if removed.any?
    puts "Removed: #{removed}"
    # TODO:
  end

  modified = modified.select { Utils::FileSystem.allow?(it) }
  if modified.any?
    puts "Modified: #{modified}"
    jobs = modified.map { IndexFileJob.new(it) }
    ActiveJob.perform_all_later(jobs) unless DRY_RUN
  end
end

puts "Environment: #{ENV["RAILS_ENV"]}"
puts "Watching: #{root_path}"
puts "Watcher backend: #{listener.instance_variable_get(:@backend).instance_variable_get(:@adapter).class}"

listener.start
sleep
