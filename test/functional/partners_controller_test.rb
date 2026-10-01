require 'test_helper'

class PartnersControllerTest < ActionController::TestCase
  def test_should_get_index
    login_as_user
    get :index
    assert_response :success
  end

  def test_should_show_partner
    login_as_user
    get :show, params: { :id => partners(:one).id }
    assert_response :success
  end

  def test_should_create_partner
    login_as_user
    assert_difference('Partner.count') do
      post :create, params: { :partner => { :name => 'Fixture created partner', :short_name => 'fixture-new-partner' } }
    end
    assert_response :redirect
  end

  def test_should_update_partner
    login_as_user
    put :update, params: { :id => partners(:one).id, :partner => { :name => 'Fixture updated partner' } }
    assert_response :redirect
  end

  def test_should_destroy_partner
    login_as_user
    target = partners(:one)
    assert_difference('Partner.count', -1) do
      delete :destroy, params: { :id => target.id }
    end
    assert_response :redirect
  end
end
