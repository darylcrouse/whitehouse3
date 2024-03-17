class BulletinsController < ApplicationController
  
  before_action :login_required, only: [:new_inline, :create]
  
  def new_inline
    @activity = ActivityBulletinNew.create(user: current_user)
    @comment = @activity.comments.build
    respond_to do |format|
      format.js
    end
  end

  def create
    @activity = ActivityBulletinNew.create(user: current_user)
    @comment = @activity.comments.build(comment_params)
    if @comment.save
      respond_to do |format|
        format.html { redirect_to bulletins_path }
        format.js 
      end
    else      
      respond_to do |format|
        format.html { render :new_inline }
        format.js { render :new_inline }        
      end
    end
  end

  private
    def comment_params
      params.require(:comment).permit(:content)
    end
end
