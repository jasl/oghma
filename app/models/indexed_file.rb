class IndexedFile < ApplicationRecord
  validates :storage_path,
            presence: true, uniqueness: true

  validates :key, :filename, :modified_at, :content_type, :byte_size, :checksum,
            presence: true

  def absolute_full_path
    Utils::FileSystem.root_path.join(storage_path).to_path
  end
end
