class Speech < Announcement
  include Edition::Appointment

  validates :speech_type_id, :delivered_on, presence: true
  before_validation :populate_organisations_based_on_role_appointment

  validate :role_appointment_has_associated_organisation

  delegate :genus, :explanation, to: :speech_type

  def speech_type
    SpeechType.find_by_id(speech_type_id)
  end

  def speech_type=(speech_type)
    self.speech_type_id = speech_type && speech_type.id
  end

  private

  def populate_organisations_based_on_role_appointment
    self.edition_organisations = []
    self.organisations = organisations_via_role_appointment
  end

  def organisations_via_role_appointment
    role_appointment && role_appointment.role && role_appointment.role.organisations || []
  end

  def set_timestamp_for_sorting
    self.timestamp_for_sorting = delivered_on
  end

  def role_appointment_has_associated_organisation
    unless organisations_via_role_appointment.any?
      errors.add(:role_appointment, "must have an associated organisation")
    end
  end
end
