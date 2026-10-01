require 'test_helper'

# The app nests revisions under points/:point_id and gates most actions on
# login/admin: see RevisionsController before_actions.
class RevisionsControllerTest < ActionController::TestCase
  def point_params(extra = {})
    { :point_id => Point.first.id }.merge(extra)
  end

  def test_should_get_index
    get :index, params: point_params
    assert_response :redirect # index redirects to the point
  end

  def test_should_get_new
    login_as_user
    get :new, params: point_params
    assert_response :success
  end

  def test_should_create_revision
    login_as_user
    assert_difference('Revision.count') do
      post :create, params: point_params(:revision => { :name => 'A revised point',
                                                        :content => 'Revised content here.' })
    end
    assert_redirected_to point_path(Point.first)
  end

  def test_should_show_revision
    get :show, params: point_params(:id => revisions(:one).id)
    assert_response :success
  end

  def test_should_get_edit
    login_as_user
    get :edit, params: point_params(:id => revisions(:one).id)
    assert_response :success
  end

  def test_should_update_revision
    login_as_user
    put :update, params: point_params(:id => revisions(:one).id, :revision => { :content => 'Updated revision content.' })
    assert_redirected_to point_revision_path(Point.first, assigns(:revision))
  end

  def test_should_destroy_revision
    login_as_user
    target = revisions(:one)
    assert_difference('Revision.count', -1) do
      delete :destroy, params: point_params(:id => target.id)
    end
    assert_redirected_to point_path(Point.first)
  end
end
