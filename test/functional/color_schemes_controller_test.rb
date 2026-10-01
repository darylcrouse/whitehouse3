require 'test_helper'

class ColorSchemesControllerTest < ActionController::TestCase
  def test_should_get_index
    login_as_user
    get :index
    assert_response :success
  end

  def test_should_get_new
    login_as_user
    get :new
    assert_response :success
  end

  def test_should_get_edit
    login_as_user
    get :edit, params: { :id => color_schemes(:one).id }
    assert_response :success
  end

  def test_should_show_color_scheme
    login_as_user
    get :show, params: { :id => color_schemes(:one).id }
    assert_response :success
  end

  def test_should_create_color_scheme
    login_as_user
    assert_difference('ColorScheme.count') do
      post :create, params: { :color_scheme => { :name => 'Fixture created scheme' } }
    end
    assert_response :redirect
  end

  def test_should_update_color_scheme
    login_as_user
    put :update, params: { :id => color_schemes(:one).id, :color_scheme => { :name => 'Fixture updated scheme' } }
    assert_response :redirect
  end

  def test_should_destroy_color_scheme
    login_as_user
    target = color_schemes(:one)
    assert_difference('ColorScheme.count', -1) do
      delete :destroy, params: { :id => target.id }
    end
    assert_response :redirect
  end
end
