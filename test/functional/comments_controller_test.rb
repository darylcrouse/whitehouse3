require 'test_helper'

# The app nests comments under activities/:activity_id and gates writes on
# login: see CommentsController before_actions.
class CommentsControllerTest < ActionController::TestCase
  def activity_params(extra = {})
    { :activity_id => Activity.first.id }.merge(extra)
  end

  def test_should_get_index
    get :index, params: activity_params
    assert_response :success
    assert_not_nil assigns(:comments)
  end

  def test_should_get_new
    login_as_user
    get :new, params: activity_params
    assert_response :success
  end

  def test_should_create_comment
    login_as_user
    assert_difference('Comment.count') do
      post :create, params: activity_params(:comment => { :content => 'A test comment.' })
    end
    assert_redirected_to activity_comments_path(Activity.first)
  end

  def test_should_show_comment
    get :show, params: activity_params(:id => comments(:one).id)
    assert_response :success
  end

  def test_should_get_edit
    login_as_user
    get :edit, params: activity_params(:id => comments(:one).id)
    assert_response :success
  end

  def test_should_update_comment
    login_as_user
    put :update, params: activity_params(:id => comments(:one).id, :comment => { :content => 'Updated comment.' })
    assert_redirected_to activity_comments_path(Activity.first)
  end

  def test_should_destroy_comment
    login_as_user
    delete :destroy, params: activity_params(:id => comments(:one).id)
    assert_redirected_to comments_url
  end
end
