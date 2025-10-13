# app/services/documents/extract_text_service.rb
require "shellwords"

module Documents
  class ExtractTextService
    def self.call(blob)
      new(blob).call
    end

    def initialize(blob)
      @blob = blob
    end

    def call
      # ActiveStorage::Blob -> 临时文件路径（避免一次性读大文件进内存）
      path = download_to_tempfile(@blob)
      text = DocRipper::Doc.new(path).to_s rescue ""
      text.to_s.encode("UTF-8", invalid: :replace, undef: :replace)
    ensure
      File.delete(path) if path && File.exist?(path)
    end

    private

    def download_to_tempfile(blob)
      tmp = Tempfile.new([ "upload", File.extname(blob.filename.to_s) ])
      tmp.binmode
      blob.download { |chunk| tmp.write(chunk) }
      tmp.flush
      tmp.path
    end
  end
end
