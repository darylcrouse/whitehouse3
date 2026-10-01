require 'test_helper'

# Admin-only scaffold controller for the tag vocabulary.
class TagsControllerTest < ActionController::TestCase
  def test_should_get_index
    login_as_user
    get :index
    assert_response :success
  end

  def test_should_show_tag
    login_as_user
    get :show, params: { :id => tags(:one).id }
    assert_response :success
  end

  def test_should_get_new
    login_as_user
    get :new
    assert_response :success
  end

  def test_should_get_edit
    login_as_user
    get :edit, params: { :id => tags(:one).id }
    assert_response :success
  end

  def test_should_create_tag
    login_as_user
    assert_difference('Tag.count') do
      post :create, params: { :tag => { :name => 'fixture-created-tag' } }
    end
    assert_response :redirect
  end

  def test_should_update_tag
    login_as_user
    put :update, params: { :id => tags(:one).id, :tag => { :name => 'fixture-updated-tag' } }
    assert_response :redirect
  end

  def test_should_destroy_tag
    login_as_user
    target = tags(:one)
    assert_difference('Tag.count', -1) do
      delete :destroy, params: { :id => target.id }
    end
    assert_response :redirect
  end
end
