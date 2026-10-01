require 'test_helper'

# Admin-only scaffold controller: index/new/preview/edit/create/update/destroy
# (no show in this app).
class BlurbsControllerTest < ActionController::TestCase
  def test_should_get_index
    login_as_user
    get :index
    assert_response :success
  end

  def test_should_get_edit
    login_as_user
    get :edit, params: { :id => blurbs(:one).id }
    assert_response :success
  end

  def test_should_create_blurb
    login_as_user
    assert_difference('Blurb.count') do
      post :create, params: { :blurb => { :name => 'Fixture created blurb' } }
    end
    assert_response :redirect
  end

  def test_should_update_blurb
    login_as_user
    put :update, params: { :id => blurbs(:one).id, :blurb => { :name => 'Fixture updated blurb' } }
    assert_response :redirect
  end

  def test_should_destroy_blurb
    login_as_user
    target = blurbs(:one)
    assert_difference('Blurb.count', -1) do
      delete :destroy, params: { :id => target.id }
    end
    assert_response :redirect
  end
end
