class FullScanJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    Rails.logger.debug "Full scan job triggers"

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
            Rails.logger.debug "New: #{Utils::FileSystem.relative_path(path)}"
            jobs << IndexFileJob.new(path)
          elsif indexed.modified_at.to_i != File.mtime(path).to_i # || entry.checksum != Utils::FileSystem.checksum(path)
            Rails.logger.debug "Modified: #{indexed.path}"
            jobs << IndexFileJob.new(path)
          end
        end

        ActiveJob.perform_all_later(jobs) if jobs.any?
      end
    end
  end
end
