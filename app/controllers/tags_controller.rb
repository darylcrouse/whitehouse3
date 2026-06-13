class TagsController < ApplicationController
  def index
    @tags = Tag.where("priorities_count > 0").popular
  end

  def show
    @tag = Tag.find_by!(slug: params[:slug])
    @priorities = @tag.priorities.merge(Priority.published).top_rank.page_list(params[:page])
  end
end
