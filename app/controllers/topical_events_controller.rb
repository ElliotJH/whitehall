class TopicalEventsController < ClassificationsController
  def index
    redirect_to :topics
  end

  def show
    @classification = TopicalEvent.find(params[:id])
    @policies = @classification.published_policies
    @publications = decorate_collection(@classification.published_publications.in_reverse_chronological_order.limit(3), PublicationesquePresenter)
    @consultations = decorate_collection(@classification.published_consultations.in_reverse_chronological_order.limit(3), PublicationesquePresenter)
    @announcements = decorate_collection(@classification.published_announcements.in_reverse_chronological_order.limit(3), AnnouncementPresenter)
    @detailed_guides = @classification.detailed_guides.published.limit(5)
    @related_classifications = @classification.related_classifications
    @recently_changed_documents = @classification.recently_changed_documents
    @featured_editions = decorate_collection(@classification.classification_featurings.limit(5), FeaturedEditionPresenter)
    set_slimmer_organisations_header(@classification.organisations)
    set_slimmer_page_owner_header(@classification.lead_organisations.first)
    set_meta_description(@classification.description)

    set_expiry 5.minutes
    respond_to do |format|
      format.html do
        @recently_changed_documents = @recently_changed_documents[0...3]
      end
      format.atom do
        @recently_changed_documents = @recently_changed_documents[0...10]
      end
    end
  end
end
