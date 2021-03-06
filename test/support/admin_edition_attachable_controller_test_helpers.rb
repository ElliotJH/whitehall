module AdminEditionAttachableControllerTestHelpers
  extend ActiveSupport::Concern

  module ClassMethods
    def should_require_alternative_format_provider_for(edition_type)
      edition_class = class_for(edition_type)
      edition_base_class_name = edition_class.base_class.name.underscore
      attachment_join_table = edition_class.reflect_on_association(:attachments).through_reflection.table_name
      attachment_join_attributes = "#{attachment_join_table}_attributes".to_sym

      test "creating an edition with an attachment but no alternative_format_provider will get a validation error" do
        post :create, edition_base_class_name => controller_attributes_for(edition_type,
          alternative_format_provider_id: "",
          attachment_join_attributes => {
            "0" => { attachment_attributes: attributes_for(:attachment) }
          }
        )

        refute assigns(edition_base_class_name).errors[:alternative_format_provider].blank?
      end

      test "updating an edition with an attachment but no alternative_format_provider will get a validation error" do
        edition = create(edition_type)

        put :update, id: edition, edition_base_class_name => controller_attributes_for_instance(edition,
          alternative_format_provider_id: "",
          attachment_join_attributes => {
            "0" => { attachment_attributes: attributes_for(:attachment) }
          }
        )

        refute assigns(edition_base_class_name).errors[:alternative_format_provider].blank?
      end
    end

    def should_allow_attachments_for(edition_type)
      edition_class = class_for(edition_type)
      edition_base_class_name = edition_class.base_class.name.underscore
      attachment_join_table = edition_class.reflect_on_association(:attachments).through_reflection.table_name
      attachment_join_attributes = "#{attachment_join_table}_attributes".to_sym

      test "new puts an empty attachment on the edition" do
        get :new

        attachments = assigns(edition_base_class_name).send(edition_class.attachment_join_table_name)
        assert_equal 1, attachments.size
        assert attachments.first.new_record?
      end

      test 'creating an edition should attach file' do
        greenpaper_pdf = fixture_file_upload('greenpaper.pdf', 'application/pdf')
        attributes = controller_attributes_for(edition_type)
        attributes[attachment_join_attributes] = {
          "0" => {
            attachment_attributes: attributes_for(:attachment, title: "attachment-title").merge(attachment_data_attributes: {
              file: greenpaper_pdf
            })
          }
        }

        post :create, edition_base_class_name => attributes

        assert assigns(edition_base_class_name).errors.empty?
        assert edition = edition_class.last
        assert_equal 1, edition.attachments.length
        attachment = edition.attachments.first
        assert_equal "attachment-title", attachment.title
        assert_equal "greenpaper.pdf", attachment.attachment_data.carrierwave_file
        assert_equal "application/pdf", attachment.content_type
        assert_equal greenpaper_pdf.size, attachment.file_size
      end

      test "creating an edition should result in a single instance of the uploaded file being cached" do
        greenpaper_pdf = fixture_file_upload('greenpaper.pdf', 'application/pdf')
        attributes = controller_attributes_for(edition_type)
        attributes[attachment_join_attributes] = {
          "0" => {
            attachment_attributes: attributes_for(:attachment, title: "attachment-title").merge(attachment_data_attributes: {
              file: greenpaper_pdf
            })
          }
        }

        AttachmentData.any_instance.expects(:file=).once

        post :create, edition_base_class_name => attributes
      end

      test "creating an edition with invalid data should leave one unsaved attachment on the instance" do
        post :create, edition_base_class_name => make_invalid(controller_attributes_for(edition_type))

        attachments = assigns(edition_base_class_name).send(edition_class.attachment_join_table_name)
        assert_equal 1, attachments.size
        assert attachments.first.new_record?
      end

      test "creating an edition with invalid data does not add an extra attachment and preserves the uploaded data" do
        greenpaper_pdf = fixture_file_upload('greenpaper.pdf')

        post :create, edition_base_class_name => make_invalid(controller_attributes_for(edition_type,
          attachment_join_attributes => {
            "0" => {
              attachment_attributes: attributes_for(:attachment).merge(
                title: 'my attachment',
                attachment_data_attributes: {
                  file: greenpaper_pdf
                }
              )
            }
          }
        ))

        attachments = assigns(edition_base_class_name).send(edition_class.attachment_join_table_name)
        assert_equal 1, attachments.size
        assert attachments.first.new_record?
        assert_equal 'my attachment', attachments.first.attachment.title
        assert_match /greenpaper.pdf$/, attachments.first.attachment.attachment_data.file_cache
      end

      view_test 'creating an edition with invalid data should not show any existing attachment info' do
        attributes = controller_attributes_for(edition_type)
        greenpaper_pdf = fixture_file_upload('greenpaper.pdf')
        attributes[attachment_join_attributes] = {
          "0" => {
            attachment_attributes: attributes_for(:attachment).merge(attachment_data_attributes: {
              file: greenpaper_pdf
            })
          }
        }

        post :create, edition_base_class_name => make_invalid(attributes)

        refute_select "p.attachment"
      end

      test "creating an edition with multiple attachments should attach all files" do
        greenpaper_pdf = fixture_file_upload('greenpaper.pdf', 'application/pdf')
        csv_file = fixture_file_upload('sample-from-excel.csv', 'text/csv')
        attributes = controller_attributes_for(edition_type)
        attributes[attachment_join_attributes] = {
          "0" => {
            attachment_attributes: attributes_for(:attachment, title: "attachment-1-title").merge(attachment_data_attributes: {
              file: greenpaper_pdf
            })
          },
          "1" => {
            attachment_attributes: attributes_for(:attachment, title: "attachment-2-title").merge(attachment_data_attributes: {
              file: csv_file
            })
          }
        }

        post :create, edition_base_class_name => attributes

        assert edition = edition_class.last
        assert_equal 2, edition.attachments.length
        attachment_1 = edition.attachments.first
        assert_equal "attachment-1-title", attachment_1.title
        assert_equal "greenpaper.pdf", attachment_1.attachment_data.carrierwave_file
        assert_equal "application/pdf", attachment_1.content_type
        assert_equal greenpaper_pdf.size, attachment_1.file_size
        attachment_2 = edition.attachments.last
        assert_equal "attachment-2-title", attachment_2.title
        assert_equal "sample-from-excel.csv", attachment_2.attachment_data.carrierwave_file
        assert_equal "text/csv", attachment_2.content_type
        assert_equal csv_file.size, attachment_2.file_size
      end

      test 'edit adds an unsaved extra attachment to the edition' do
        two_page_pdf = fixture_file_upload('two-pages.pdf', 'application/pdf')
        attachment = create(:attachment, title: "attachment-title", file: two_page_pdf)
        edition = create(edition_type, :with_alternative_format_provider, attachments: [attachment])

        get :edit, id: edition

        attachments = assigns(edition_base_class_name).send(edition_class.attachment_join_table_name)
        assert_equal 2, attachments.size
        assert_equal 'attachment-title', attachments.first.attachment.title
        assert attachments.last.new_record?
      end

      test 'updating an edition should attach file' do
        greenpaper_pdf = fixture_file_upload('greenpaper.pdf', 'application/pdf')
        edition = create(edition_type, :with_alternative_format_provider)

        put :update, id: edition, edition_base_class_name => controller_attributes_for_instance(edition,
          attachment_join_attributes => {
            "0" => {
              attachment_attributes: attributes_for(:attachment, title: "attachment-title").merge(attachment_data_attributes: {
                file: greenpaper_pdf
              })
            }
          }
        )

        edition.reload
        assert_equal 1, edition.attachments.length
        attachment = edition.attachments.first
        assert_equal "attachment-title", attachment.title
        assert_equal "greenpaper.pdf", attachment.attachment_data.carrierwave_file
        assert_equal "application/pdf", attachment.content_type
        assert_equal greenpaper_pdf.size, attachment.file_size
      end

      test 'updating an edition should attach multiple files' do
        greenpaper_pdf = fixture_file_upload('greenpaper.pdf', 'application/pdf')
        csv_file = fixture_file_upload('sample-from-excel.csv', 'text/csv')
        edition = create(edition_type, :with_alternative_format_provider)

        put :update, id: edition, edition_base_class_name => controller_attributes_for_instance(edition,
          attachment_join_attributes => {
            "0" => {
              attachment_attributes: attributes_for(:attachment, title: "attachment-1-title").merge(attachment_data_attributes: {
                file: greenpaper_pdf
              })
            },
            "1" => {
              attachment_attributes: attributes_for(:attachment, title: "attachment-2-title").merge(attachment_data_attributes: {
                file: csv_file
              })
            }
          }
        )

        edition.reload
        assert_equal 2, edition.attachments.length
        attachment_1 = edition.attachments.first
        assert_equal "attachment-1-title", attachment_1.title
        assert_equal "greenpaper.pdf", attachment_1.attachment_data.carrierwave_file
        assert_equal "application/pdf", attachment_1.content_type
        assert_equal greenpaper_pdf.size, attachment_1.file_size
        attachment_2 = edition.attachments.last
        assert_equal "attachment-2-title", attachment_2.title
        assert_equal "sample-from-excel.csv", attachment_2.attachment_data.carrierwave_file
        assert_equal "text/csv", attachment_2.content_type
        assert_equal csv_file.size, attachment_2.file_size
      end

      view_test "updating an edition with invalid data should still add a blank unsaved attachment to the edition" do
        edition = create(edition_type)
        put :update, id: edition, edition_base_class_name => make_invalid(controller_attributes_for_instance(edition))

        attachments = assigns(edition_base_class_name).send(edition_class.attachment_join_table_name)
        assert_equal 1, attachments.size
        assert attachments.first.new_record?
      end

      test "updating an edition with invalid data does not add an unsaved attachment, and preserves the uploaded data" do
        edition = create(edition_type)
        greenpaper_pdf = fixture_file_upload('greenpaper.pdf')

        put :update, id: edition, edition_base_class_name => make_invalid(controller_attributes_for(edition_type,
          attachment_join_attributes => {
            "0" => {
              attachment_attributes: attributes_for(:attachment).merge(
                title: 'my attachment',
                attachment_data_attributes: {
                  file: greenpaper_pdf
                }
              )
            }
          }
        ))

        attachments = assigns(edition_base_class_name).send(edition_class.attachment_join_table_name)
        assert_equal 1, attachments.size
        assert attachments.first.new_record?
        assert_equal 'my attachment', attachments.first.attachment.title
        assert_match /greenpaper.pdf$/, attachments.first.attachment.attachment_data.file_cache
      end

      test "updating a stale edition should still add an unsaved attachment instance" do
        edition = create_draft(edition_type)
        lock_version = edition.lock_version
        edition.touch

        put :update, id: edition, edition_base_class_name => controller_attributes_for_instance(edition, lock_version: lock_version)

        attachments = assigns(edition_base_class_name).send(edition_class.attachment_join_table_name)
        assert_equal 1, attachments.size
        assert attachments.first.new_record?
      end

      test "updating a stale edition should not add an unsaved attachment, and preseve the uploaded data" do
        greenpaper_pdf = fixture_file_upload('greenpaper.pdf')
        edition = create_draft(edition_type)
        lock_version = edition.lock_version
        edition.touch

        put :update, id: edition, edition_base_class_name => controller_attributes_for_instance(edition,
          lock_version: lock_version,
          attachment_join_attributes => {
            "0" => {
              attachment_attributes: attributes_for(:attachment).merge(
                title: 'my attachment',
                attachment_data_attributes: {
                  file: greenpaper_pdf
                }
              )
            }
          }
        )

        attachments = assigns(edition_base_class_name).send(edition_class.attachment_join_table_name)
        assert_equal 1, attachments.size
        assert attachments.first.new_record?
        assert_equal 'my attachment', attachments.first.attachment.title
        assert_match /greenpaper.pdf$/, attachments.first.attachment.attachment_data.file_cache
      end

      test 'updating should allow removal of attachments' do
        attachment_1 = create(:attachment)
        attachment_2 = create(:attachment)
        edition = create(edition_type, :with_alternative_format_provider)
        edition_attachment_1 = create("#{edition_base_class_name}_attachment", edition_base_class_name => edition, attachment: attachment_1)
        edition_attachment_2 = create("#{edition_base_class_name}_attachment", edition_base_class_name => edition, attachment: attachment_2)

        put :update, id: edition, edition_base_class_name => controller_attributes_for_instance(edition,
          attachment_join_attributes => {
            "0" => { id: edition_attachment_1.id.to_s, _destroy: "1" },
            "1" => { id: edition_attachment_2.id.to_s, _destroy: "0" },
            "2" => {
              attachment_attributes: {
                attachment_data_attributes: { file_cache: "" }
              }
            }
          }
        )

        assert assigns(edition_base_class_name).errors.empty?
        edition.reload
        assert_equal [attachment_2], edition.attachments
      end

      test 'updating should respect the attachment_action attribute to keep, remove, or replace attachments' do
        two_pages_pdf = fixture_file_upload('two-pages.pdf')
        greenpaper_pdf = fixture_file_upload('greenpaper.pdf')

        attachment_1 = create(:attachment, file: File.open(File.join(Rails.root, 'test', 'fixtures', 'whitepaper.pdf')))
        attachment_1_data = attachment_1.attachment_data
        attachment_2 = create(:attachment, file: File.open(File.join(Rails.root, 'test', 'fixtures', 'greenpaper.pdf')))
        attachment_3 = create(:attachment, file: File.open(File.join(Rails.root, 'test', 'fixtures', 'three-pages.pdf')))
        attachment_3_data = attachment_3.attachment_data

        edition = create(edition_type, :with_alternative_format_provider)
        edition_attachment_1 = create("#{edition_base_class_name}_attachment", edition_base_class_name => edition, attachment: attachment_1)
        edition_attachment_2 = create("#{edition_base_class_name}_attachment", edition_base_class_name => edition, attachment: attachment_2)
        edition_attachment_3 = create("#{edition_base_class_name}_attachment", edition_base_class_name => edition, attachment: attachment_3)

        put :update, id: edition, edition_base_class_name => controller_attributes_for_instance(edition,
          attachment_join_attributes => {
            "0" => { id: edition_attachment_1.id.to_s, attachment_attributes: {
              id: attachment_1.id,
              attachment_action: 'keep'
            }},
            "1" => { id: edition_attachment_2.id.to_s, attachment_attributes: {
              id: attachment_2.id,
              attachment_action: 'remove'
            }},
            "2" => { id: edition_attachment_3.id.to_s, attachment_attributes: {
              id: attachment_3.id,
              attachment_action: 'replace',
              attachment_data_attributes: {
                file: two_pages_pdf,
                to_replace_id: attachment_3.attachment_data.id
              }
            }},
            "3" => { attachment_attributes: attributes_for(:attachment).merge(
              attachment_data_attributes: { file: greenpaper_pdf }
            )}
          }
        )

        assert assigns(edition_base_class_name).errors.empty?
        edition.reload
        assert_equal 3, edition.attachments.size
        assert edition.attachments.include?(attachment_1)
        assert !edition.attachments.include?(attachment_2)
        assert edition.attachments.include?(attachment_3)

        assert_raise(ActiveRecord::RecordNotFound) do
          attachment_2.reload
        end

        assert_equal attachment_1_data, attachment_1.reload.attachment_data

        new_attachment_3_data = attachment_3.reload.attachment_data
        assert_not_equal attachment_3_data, new_attachment_3_data
        assert_equal "two-pages.pdf", new_attachment_3_data.carrierwave_file
        assert_equal new_attachment_3_data, attachment_3_data.reload.replaced_by

        attachment_4 = edition.attachments.last
        assert_equal "greenpaper.pdf", attachment_4.attachment_data.carrierwave_file
      end
    end
  end

  def create_draft(edition_type)
    create("draft_#{edition_type}")
  end

  def make_invalid(controller_attributes)
    controller_attributes.merge(title: "")
  end
end
