# app/models/document.rb
class Document < ApplicationRecord
  has_one_attached :file

  validates :file, presence: true
  validate :acceptable_file

  def acceptable_file
    return unless file.attached?
    if file.blob.byte_size > 15.megabytes
      errors.add :file, "文件过大（≤ 15MB）"
    end
    ok_types = %w[
      application/pdf
      application/msword
      application/vnd.openxmlformats-officedocument.wordprocessingml.document
      text/plain
      text/markdown
    ]
    errors.add(:file, "不支持的格式") unless ok_types.include?(file.content_type)
  end
end
