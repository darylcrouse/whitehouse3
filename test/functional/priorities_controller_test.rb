require 'test_helper'

class PrioritiesControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:issues)
  end

  def test_should_get_new
    login_as_user
    get :new
    assert_response :success
  end

  def test_should_get_edit
    login_as_user
    get :edit, params: { :id => priorities(:one).id }
    assert_response :success
  end

  def test_should_create_priority
    login_as_user
    assert_difference('Priority.count') do
      post :create, params: { :priority => { :name => 'Fixture created priority' } }
    end
    assert_response :redirect
  end

  def test_should_show_priority
    get :show, params: { :id => priorities(:one).id }
    assert_response :success
  end

  def test_should_update_priority
    login_as_user
    put :update, params: { :id => priorities(:one).id, :priority => { :name => 'Fixture updated priority' } }
    assert_response :redirect
  end

  def test_should_destroy_priority
    login_as_user
    delete :destroy, params: { :id => priorities(:one).id }
    assert_response :redirect
  end
end
