class OperationalFieldsController < PublicFacingController
  def index
    @operational_fields = OperationalField.all
  end

  def show
    @operational_field = OperationalField.find(params[:id])
    @organisation = Organisation.where(handles_fatalities: true).first
    @fatality_notices = @operational_field.published_fatality_notices.in_reverse_chronological_order.map do |fatality_notice|
      FatalityNoticePresenter.new(fatality_notice)
    end
  end
end
