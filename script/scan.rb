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
  "--force-reindex",
  "Force index even there is no change"
) do
  ENV["FORCE_REINDEX"] = "1"
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
_ret = parser.parse!

# Load Rails environment
require_relative "../config/environment"

FORCE_REINDEX = Utils::Cli.true? ENV["FORCE_REINDEX"]
DRY_RUN = Utils::Cli.true? ENV["DRY_RUN"]
VERBOSE = Utils::Cli.true? ENV["VERBOSE"]

root_path = Utils::FileSystem.root_path.to_path
dir_retrieve_stacks = [root_path]
loop do
  break if dir_retrieve_stacks.empty?

  current_path = dir_retrieve_stacks.pop

  scanned_files = []
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

    scanned_files << path
  end

  scanned_files.each_slice(32) do |sliced_scanned_files|
    indexed_files = IndexedFile.where(
      key: sliced_scanned_files.map { Utils::FileSystem.path_checksum(it) }
    ).to_a

    jobs = []
    sliced_scanned_files.select do |path|
      indexed = indexed_files.find { it.absolute_full_path == path }
      if indexed.blank?
        puts "New: #{Utils::FileSystem.relative_path(path)}"
        jobs << IndexFileJob.new(path)
      elsif FORCE_REINDEX || indexed.modified_at.to_i != File.mtime(path).to_i # || entry.checksum != Utils::FileSystem.checksum(path)
        puts "Modified: #{indexed.storage_path}"
        jobs << IndexFileJob.new(path)
      end
    end
    ActiveJob.perform_all_later(jobs) if jobs.any? && !DRY_RUN
  end
end
