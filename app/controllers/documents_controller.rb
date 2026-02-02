# app/controllers/documents_controller.rb
class DocumentsController < ApplicationController
  protect_from_forgery with: :exception

  def new
    @document = Document.new
  end

  def create
    @document = Document.new(title: params.dig(:document, :title))

    uploaded_file = params.dig(:document, :file)

    if uploaded_file.blank?
      @document.errors.add(:file, "必须上传一个 .docx 文件")
      return render :new, status: :unprocessable_entity
    end

    unless docx_file?(uploaded_file)
      @document.errors.add(:file, "目前只支持 .docx 格式的 Word 文件")
      return render :new, status: :unprocessable_entity
    end

    @document.file.attach(uploaded_file)

    if @document.save
      content = Documents::ExtractTextService.call(@document.file.blob).to_s.strip
      @document.update!(content: content)
      redirect_to document_path(@document), notice: "上传成功，已解析正文"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @document = Document.find(params[:id])
  end

  def analyze
    doc  = Document.find(params[:id])
    text = params[:text].to_s
    issues = Ai::AnalyzerService.call(text)
    render json: { issues: issues }
  end

  private

  def docx_file?(uploaded_file)
    content_type = uploaded_file.content_type.to_s
    filename_ext = File.extname(uploaded_file.original_filename).downcase

    valid_mime = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    (content_type == valid_mime) || (filename_ext == ".docx")
  end
end
