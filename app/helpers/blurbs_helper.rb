module BlurbsHelper

  # Blurb content is site-authored markup (DB rows / liquid templates); Rails 2
  # output it raw, Rails 8 would escape it into visible source text. Keep the
  # legacy behavior.
  def blurb(name)
    if liquid_blurb = Blurb.fetch_liquid(name)
      return ('<div id="blurb_' + name + '" class="blurb">' + liquid_blurb.render({"government" => current_government, "user" => current_user}, :filters => [LiquidFilters]) + '</div>').html_safe
    end
  end

end
