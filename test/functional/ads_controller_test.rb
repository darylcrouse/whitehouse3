require 'test_helper'

# Nested under priorities/:priority_id; no edit/update/destroy in this app.
class AdsControllerTest < ActionController::TestCase
  def ad_params(extra = {})
    { :priority_id => Priority.first.id }.merge(extra)
  end

  def valid_ad
    { :content => 'Buy this test ad.', :cost => 5, :show_ads_count => 100 }
  end

  def test_should_get_index
    get :index, params: ad_params
    assert_redirected_to priority_url(Priority.first)
  end

  def test_should_get_new
    login_as_user
    Priority.first.update_columns(:position => 30)
    get :new, params: ad_params
    assert_response :success
  end

  def test_should_create_ad
    login_as_user
    assert_difference('Ad.count') do
      post :create, params: ad_params(:ad => valid_ad)
    end
    assert_response :redirect
  end

  def test_should_show_ad
    get :show, params: ad_params(:id => ads(:one).id)
    assert_response :success
  end
end
