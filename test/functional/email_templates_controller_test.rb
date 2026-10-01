require 'test_helper'

# Admin-only; templates are keyed by name (fetch_default on new).
class EmailTemplatesControllerTest < ActionController::TestCase
  def test_should_get_index
    login_as_user
    get :index
    assert_response :success
    assert_not_nil assigns(:templates)
  end

  def test_should_get_new
    login_as_user
    get :new, params: { :name => 'welcome' }
    assert_response :success
  end

  def test_should_create_email_template
    login_as_user
    assert_difference('EmailTemplate.count') do
      post :create, params: { :email_template => { :name => 'fixture_new_template' } }
    end
    assert_response :redirect
  end

  def test_should_update_email_template
    login_as_user
    put :update, params: { :id => email_templates(:one).id, :email_template => { :subject => 'Updated subject' } }
    assert_response :redirect
  end

  def test_should_destroy_email_template
    login_as_user
    target = email_templates(:one)
    assert_difference('EmailTemplate.count', -1) do
      delete :destroy, params: { :id => target.id }
    end
    assert_response :redirect
  end
end
