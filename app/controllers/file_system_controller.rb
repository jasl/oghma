class FileSystemController < ApplicationController
  def index
    requested_path = params[:requested_path].to_s
    if requested_path.include?("./")
      render status: :bad_request,
             json: {
               error: {
                 code: "BAD_REQUESTED_PATH",
               },
             }
      return
    end

    current_path = Utils::FileSystem.root_path.join(requested_path)
    unless File.exist?(current_path)
      render status: :not_found,
             json: {
               error: {
                 code: "NOT_FOUND",
               },
             }
      return
    end

    if File.directory?(current_path)
      files = Dir.glob("#{current_path}/*")
      unless Utils::Cli.true? params[:all]
        files.select! { Utils::FileSystem.allow?(it) }
      end

      indexed_files = IndexedFile.where(
        key: files.map { Utils::FileSystem.path_checksum(it) }
      ).to_a

      render json: {
        directory: {
          full_path: Utils::FileSystem.relative_path(current_path),
          entries: files.map do |path|
            relative_path = Utils::FileSystem.relative_path(path).to_path
            indexed_file = indexed_files.find { it.storage_path == relative_path }

            {
              filename: indexed_file&.filename || Utils::FileSystem.filename(path),
              type: File.directory?(path) ? "directory" : "file",
              indexed: indexed_file.present?,
              metadata: indexed_file.blank? ? nil : {
                key: indexed_file.key,
                checksum: indexed_file.checksum,
                byte_size: indexed_file.byte_size,
                content_type: indexed_file.content_type,
              },
            }
          end,
        },
      }
    else
      relative_path = Utils::FileSystem.relative_path(current_path).to_path
      indexed_file = IndexedFile.find_by(storage_path: relative_path)
      render json: {
        full_path: indexed_file&.storage_path || Utils::FileSystem.relative_path(current_path).to_path,
        filename: indexed_file&.filename || Utils::FileSystem.filename(relative_path),
        type: "file",
        indexed: indexed_file.present?,
        metadata: indexed_file.blank? ? nil : {
          key: indexed_file.key,
          checksum: indexed_file.checksum,
          byte_size: indexed_file.byte_size,
          content_type: indexed_file.content_type,
        },
      }
    end
  end
end
