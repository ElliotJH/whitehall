require 'test_helper'

class Admin::ResponsesControllerTest < ActionController::TestCase
  should_be_an_admin_controller

  setup do
    login_as :policy_writer
    @consultation = create(:closed_consultation)
  end

  view_test "GET :show has a link for adding a response" do
    get :show, consultation_id: @consultation

    assert_response :success
    assert_select 'a', text: 'Add a response'
  end

  view_test "GET :show displays the details and an edit link if the consultation has a respones" do
    response = create_response
    get :show, consultation_id: @consultation

    assert_response :success
    assert_select 'p', text: 'A summary of the response'
    assert_select 'a', text: 'Edit response'
  end

  view_test "GET :new renders a response form" do
    get :new, consultation_id: @consultation

    assert_response :success
    assert_select "textarea[name='response[summary]']"
  end

  test "POST :create with valid response params saves the response and redirects" do
    post :create, consultation_id: @consultation, response: { summary: 'Response summary' }

    assert_response :redirect
    assert response = @consultation.response
    assert_equal 'Response summary', response.summary
  end

  view_test "GET :edit renders the edit form" do
    response = create_response
    get :edit, consultation_id: @consultation
    assert_select 'textarea', text: response.summary
  end

  test "PUT :create with valid response params saves the changes to the response" do
    response = create_response
    put :update, consultation_id: @consultation, response: { summary: 'New summary' }
    assert_response :redirect
    assert_equal 'New summary', response.reload.summary
  end


  def create_response
    @consultation.create_response!(summary: 'A summary of the response')
  end
end
