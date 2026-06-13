class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  PER_PAGE = 25

  # Minimal, dependency-free pagination. Returns a limited/offset relation; the
  # view helper `pager` renders prev/next based on params[:page].
  def self.page_list(page, per = PER_PAGE)
    page = page.to_i
    page = 1 if page < 1
    limit(per).offset((page - 1) * per)
  end
end
