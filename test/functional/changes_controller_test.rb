require 'test_helper'

# The app nests changes under priorities/:priority_id and gates edits on
# login/admin: see ChangesController before_actions.
class ChangesControllerTest < ActionController::TestCase
  def priority_params(extra = {})
    { :priority_id => Priority.first.id }.merge(extra)
  end

  def test_should_get_index
    get :index, params: priority_params
    assert_response :success
    assert_not_nil assigns(:changes)
  end

  def test_should_get_new
    login_as_user
    get :new, params: priority_params
    assert_response :success
  end

  def test_should_create_change
    login_as_user
    assert_difference('Change.count') do
      post :create, params: priority_params(:change => { :new_priority_id => Priority.last.id })
    end
    assert_redirected_to priority_change_path(Priority.first, assigns(:change))
  end

  def test_should_show_change
    get :show, params: priority_params(:id => changes(:one).id)
    assert_response :success
  end

  def test_should_get_edit
    login_as_user
    get :edit, params: priority_params(:id => changes(:one).id)
    assert_response :success
  end

  def test_should_update_change
    login_as_user
    put :update, params: priority_params(:id => changes(:one).id, :change => { :content => 'Updated change content.' })
    assert_redirected_to priority_changes_path(assigns(:change))
  end

  def test_should_destroy_change
    login_as_user
    delete :destroy, params: priority_params(:id => changes(:one).id)
    assert_redirected_to changes_url
  end
end
