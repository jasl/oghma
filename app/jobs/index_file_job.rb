class IndexFileJob < ApplicationJob
  queue_as :default

  def perform(file_path)
    unless File.exist?(file_path)
      return
    end

    record = IndexedFile.find_or_initialize_by(
      key: Utils::FileSystem.path_checksum(file_path),
      storage_path: Utils::FileSystem.relative_path(file_path).to_path,
    )

    record.filename = Utils::FileSystem.filename(file_path)
    record.modified_at = File.mtime(file_path)
    record.content_type = Utils::FileSystem.mime_type(file_path)
    record.byte_size = File.size(file_path)
    record.checksum = Utils::FileSystem.file_checksum(file_path)

    record.save!

    # t.string :filename, null: false, comment: "original filename"
    # t.string :storage_path, null: false, comment: "original storage path (relative to the root)"
    # t.timestamp :modified_at, null: false, comment: "original file's `mtime` attribute"
    #
    # t.string :content_type, null: false, comment: "Detected media type"
    # t.bigint :byte_size, null: false
    # t.string :checksum, null: false
  end
end
