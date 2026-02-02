# app/services/documents/extract_text_service.rb
require "docx"

module Documents
  class ExtractTextService
    def self.call(blob)
      new(blob).call
    end

    def initialize(blob)
      @blob = blob
    end

    def call
      return "" if @blob.blank?
      return "" unless docx_blob?(@blob)

      extract_from_docx(@blob)
    rescue => e
      Rails.logger.error("[ExtractTextService] #{e.class}: #{e.message}")
      ""
    end

    private

    def docx_blob?(blob)
      filename_ext = File.extname(blob.filename.to_s).downcase
      content_type = blob.content_type.to_s
      valid_mime   = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"

      filename_ext == ".docx" || content_type == valid_mime
    end

    def extract_from_docx(blob)
      Tempfile.open([ "document", ".docx" ]) do |file|
        file.binmode
        file.write(blob.download)
        file.rewind

        doc = Docx::Document.open(file.path)
        # 每个段落一行
        text = doc.paragraphs.map(&:text).join("\n")
        text.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
      end
    end
  end
end
