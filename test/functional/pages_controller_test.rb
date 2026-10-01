require 'test_helper'

# Admin-only; pages require name + short_name.
class PagesControllerTest < ActionController::TestCase
  def test_should_get_index
    login_as_user
    get :index
    assert_response :success
  end

  def test_should_show_page
    login_as_user
    get :show, params: { :id => pages(:one).short_name }
    assert_response :success
  end

  def test_should_get_new
    login_as_user
    get :new
    assert_response :success
  end

  def test_should_get_edit
    login_as_user
    get :edit, params: { :id => pages(:one).id }
    assert_response :success
  end

  def test_should_create_page
    login_as_user
    assert_difference('Page.count') do
      post :create, params: { :page => { :name => 'Fixture created page', :short_name => 'fixture-created-page' } }
    end
    assert_response :redirect
  end

  def test_should_update_page
    login_as_user
    put :update, params: { :id => pages(:one).id, :page => { :name => 'Fixture updated page' } }
    assert_response :success
  end

  def test_should_destroy_page
    login_as_user
    target = pages(:one)
    assert_difference('Page.count', -1) do
      delete :destroy, params: { :id => target.id }
    end
    assert_response :redirect
  end
end
