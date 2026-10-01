require 'test_helper'

# Nested under priorities for collection actions; login on writes,
# admin on update/edit; deletes are soft (delete!).
class PointsControllerTest < ActionController::TestCase
  def priority_params(extra = {})
    { :priority_id => Priority.first.id }.merge(extra)
  end

  def point_params(extra = {})
    { :id => points(:one).id }.merge(extra)
  end

  def test_should_get_index
    login_as_user
    get :index
    assert_response :success
  end

  def test_should_get_new
    login_as_user
    get :new, params: priority_params
    assert_response :success
  end

  def test_should_create_point
    login_as_user
    assert_difference('Point.count') do
      post :create, params: priority_params(:point => { :name => 'Fixture created point', :content => 'Created point content.' })
    end
    assert_response :redirect
  end

  def test_should_show_point
    get :show, params: point_params
    assert_response :success
  end

  def test_should_get_edit
    login_as_user
    get :edit, params: point_params
    assert_response :success
  end

  def test_should_update_point
    login_as_user
    put :update, params: point_params(:point => { :content => 'Updated point content.' })
    assert_response :redirect
  end

  def test_should_destroy_point
    login_as_user
    delete :destroy, params: point_params
    assert_response :redirect
  end
end
