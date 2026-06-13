require "test_helper"

class UserFlowTest < ActionDispatch::IntegrationTest
  test "the leaderboard is publicly viewable" do
    Priority.create!(name: "Open the budget to the public", status: "published")
    get root_path
    assert_response :success
    assert_select "title", /White House/
  end

  test "a visitor can sign up and is signed in" do
    assert_difference "User.count", 1 do
      post users_path, params: { user: {
        login: "newbie", email_address: "newbie@example.com",
        password: "password123", password_confirmation: "password123"
      } }
    end
    assert_redirected_to root_path
    follow_redirect!
    assert_match "My priorities", response.body
  end

  test "endorsing requires login" do
    p = Priority.create!(name: "Make transit free", status: "published")
    post endorse_priority_path(p)
    assert_redirected_to login_path
  end

  test "a logged-in user can endorse a priority" do
    user = create_user("activist")
    p = Priority.create!(name: "Expand parks", status: "published")
    post session_path, params: { email_address: user.email_address, password: "password123" }
    assert_difference "Endorsement.count", 1 do
      post endorse_priority_path(p)
    end
    assert user.reload.endorsed?(p)
  end

  test "admin area is protected from non-admins" do
    user = create_user("regular")
    post session_path, params: { email_address: user.email_address, password: "password123" }
    get admin_root_path
    assert_redirected_to root_path
  end
end
