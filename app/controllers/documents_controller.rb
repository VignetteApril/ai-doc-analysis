# app/controllers/documents_controller.rb
class DocumentsController < ApplicationController
  protect_from_forgery with: :exception

  def new
    @document = Document.new
  end

  def create
    @document = Document.new(title: params.dig(:document, :title))
    @document.file.attach(params.require(:document).fetch(:file))

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
    issues = Ai::AnalyzerService.call(text) # 用你已有的 mock/真实实现
    render json: { issues: issues }
  end
end
