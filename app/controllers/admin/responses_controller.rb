class Admin::ResponsesController < Admin::BaseController
  before_filter :find_consultation
  before_filter :load_response, before: [:edit, :update]

  def show
    @response = @consultation.response
  end

  def new
    @response = @consultation.build_response
  end

  def create
    @response = @consultation.build_response(params[:response])
    if @response.save
      redirect_to admin_consultation_response_path, notice: 'Response saved'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @response.update_attributes(params[:response])
      redirect_to admin_consultation_response_path, notice: 'Response updated'
    else
      render :edit
    end
  end

  private

  def find_consultation
    @consultation = Consultation.find(params[:consultation_id])
  end

  def load_response
    @response = @consultation.response
  end
end
