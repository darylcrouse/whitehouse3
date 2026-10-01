class Blurb < ActiveRecord::Base

  NAMES = ["intro", "header", "footer", "rules", "warnings", "signup_intro", "invite_intro", "not_verified", "partner_intro", "signup_quick", "privacy", "faq", "about", "textile", "ad_intro", "ad_new", "acquisition_new", "document_new", "docs_needed_intro", "point_new", "point_revision_new", "points_needed_intro", "tags_intro", "your_network_intro", "sorting_instruct", "sorting_instruct_adv", "overview_more", "network_intro", "account_delete", "legislators_intro", "people_you_know_intro", "about_menu_extra"]

  validates_presence_of :name
  validates_uniqueness_of :name

  after_save :clear_cache
  
  def clear_cache
    Rails.cache.delete('blurb-' + name)
    return true
  end

  def Blurb.fetch_liquid(name)
    # Cache the template *source*: Liquid::Template instances contain anonymous
    # classes and cannot be serialized (which the cache layer does even on
    # NullStore in Rails 8, and file stores in production).
    source = Rails.cache.read("blurb-" + name)
    if source.nil?
      blurb = Blurb.find_by_name(name)
      source = blurb ? blurb.content : Blurb.fetch_default(name)
      Rails.cache.write("blurb-" + name, source.to_s)
    end
    return Liquid::Template.parse(source.to_s)
  end

  def Blurb.fetch_default(name)
    path = Rails.root.join("app/views/blurbs/defaults", "#{name}.html.liquid")
    return '' unless File.exist?(path)
    File.read(path)
  end

end
