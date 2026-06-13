class DocumentsController < ApplicationController
  before_action :require_login, only: %i[new create edit update destroy]
  before_action :set_priority, only: %i[index new create edit update destroy], if: -> { params[:priority_id] }
  before_action :set_document, only: %i[show edit update destroy]

  def index
    if @priority
      @documents = @priority.documents.published.newest.page_list(params[:page])
    else
      @documents = Document.published.newest.page_list(params[:page])
    end
  end

  def show
    @document ||= Document.find(params[:id])
    @priority = @document.priority
  end

  def new
    @document = @priority.documents.new(value: params[:value] || 1)
  end

  def create
    @document = @priority.documents.new(document_params)
    @document.user = current_user
    if @document.save
      redirect_to priority_document_path(@priority, @document), notice: "Your document was published."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @document.update(document_params)
      redirect_to priority_document_path(@document.priority, @document), notice: "Document updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @document.destroy if current_user&.admin? || @document.user_id == current_user&.id
    redirect_to priority_path(@document.priority), notice: "Document removed."
  end

  private

  def set_priority
    @priority = Priority.find(params[:priority_id].to_i)
  end

  def set_document
    @document = Document.find(params[:id])
  end

  def document_params
    params.require(:document).permit(:name, :content, :value)
  end
end
