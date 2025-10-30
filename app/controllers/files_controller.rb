class FilesController < ApplicationController
  def show
    root_path = Utils::FileSystem.root_path
    current_path = root_path.join(params[:requested_path].to_s)
    unless File.exist?(current_path)
      render status: :not_found,
             json: {
               error: {
                 code: "NOT_FOUND",
               },
             }
      return
    end

    relative_path = Utils::FileSystem.relative_path(current_path, skip_exist_check: true)

    if File.directory?(current_path)
      files = Dir["#{current_path}/*"]
      unless Utils::Cli.true? params[:all]
        files.select! { Utils::FileSystem.allow? it }
      end
      files.map! { Utils::FileSystem.relative_path(it, skip_exist_check: true) }

      render json: {
        directory: {
          path: relative_path,
          files: files,
        },
      }
    else
      render json: {
        file: {
          path: relative_path,
        },
      }
    end
  end
end
