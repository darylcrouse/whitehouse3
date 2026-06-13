module ApplicationHelper
  def page_title(title)
    content_for(:title) { title }
  end

  # Minimal prev/next pager for a `page_list` collection.
  def pager(collection, per = ApplicationRecord::PER_PAGE)
    page = (params[:page] || 1).to_i
    page = 1 if page < 1
    has_prev = page > 1
    has_next = collection.size >= per
    return "" unless has_prev || has_next
    content_tag :div, class: "pager" do
      safe_join([
        has_prev ? link_to("← Newer", url_for(request.query_parameters.merge(page: page - 1))) : content_tag(:span, "← Newer"),
        content_tag(:span, "Page #{page}"),
        has_next ? link_to("Older →", url_for(request.query_parameters.merge(page: page + 1))) : content_tag(:span, "Older →")
      ])
    end
  end

  def avatar(user, size = 36)
    image_tag user.gravatar_url(size * 2), width: size, height: size, class: "avatar", alt: user.name, loading: "lazy"
  end

  def relative_time(time)
    return "" unless time
    content_tag :span, "#{time_ago_in_words(time)} ago", title: time.strftime("%B %-d, %Y %H:%M")
  end

  def endorsement_badge(user, priority)
    if user.endorsed?(priority)
      content_tag :span, "endorser", class: "badge badge-up"
    elsif user.opposed?(priority)
      content_tag :span, "opposer", class: "badge badge-down"
    end
  end

  def gov
    Government.current
  end
end
