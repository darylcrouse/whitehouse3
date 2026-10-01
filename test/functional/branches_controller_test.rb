require 'test_helper'

class BranchesControllerTest < ActionController::TestCase
  def test_should_get_index
    login_as_user
    get :index
    assert_response :success
  end

  def test_should_get_edit
    login_as_user
    get :edit, params: { :id => branches(:one).id }
    assert_response :success
  end

  def test_should_create_branch
    login_as_user
    assert_difference('Branch.count') do
      post :create, params: { :branch => { :name => 'Fixture branch A' } }
    end
    assert_response :redirect
  end

  def test_should_update_branch
    login_as_user
    put :update, params: { :id => branches(:one).id, :branch => { :name => 'Fixture branch B' } }
    assert_response :redirect
  end

  def test_should_destroy_branch
    login_as_user
    target = branches(:one)
    assert_difference('Branch.count', -1) do
      delete :destroy, params: { :id => target.id }
    end
    assert_response :redirect
  end
end
