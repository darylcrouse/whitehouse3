class EmailTemplate < ActiveRecord::Base

  NAMES = ["welcome","invitation","new_password","notification_comment","notification_comment_flagged","notification_contact_joined","notification_invitation_accepted","notification_document_revision","notification_follower","notification_message","notification_point_revision","notification_priority_finished","notification_priority_flagged","notification_profile_bulletin","notification_warning1","notification_warning2","notification_warning3"]

  validates_presence_of :name
  validates_uniqueness_of :name

  after_save :clear_cache
  
  def clear_cache
    Rails.cache.delete("email_template_source-" + name)
    Rails.cache.delete("email_template_subject_source-" + name)
    return true
  end

  def EmailTemplate.fetch_liquid(name)
    # Cache the template SOURCE, not the parsed Liquid::Template object:
    # cache stores serialize their entries, and a parsed template graph
    # contains anonymous classes that cannot be dumped.
    source = Rails.cache.fetch("email_template_source-#{name}") do
      template = EmailTemplate.find_by_name(name)
      template ? template.content : EmailTemplate.fetch_default(name)
    end
    Liquid::Template.parse(source)
  end
  
  def EmailTemplate.fetch_default(name)
    File.open(RAILS_ROOT + "/app/views/email_templates/defaults/" + name + ".html.liquid", "r").read    
  end

  def EmailTemplate.fetch_subject_liquid(name)
    source = Rails.cache.fetch("email_template_subject_source-#{name}") do
      template = EmailTemplate.find_by_name(name)
      template ? template.subject : EmailTemplate.fetch_subject_default(name)
    end
    Liquid::Template.parse(source)
  end

  def EmailTemplate.fetch_subject_default(name)
    File.open(RAILS_ROOT + "/app/views/email_templates/defaults/" + name + "_subject.html.liquid", "r").read    
  end

end
