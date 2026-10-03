class UserMailer < ActionMailer::Base

  # Modernized (Rails 8) ActionMailer. The 2009 code used the Rails-2 API
  # (@recipients/@subject/@body); call sites still invoke the deliver_* form,
  # which LegacyMailerDeliver (config/initializers/legacy_support.rb) maps to
  # <action>.deliver_now.
  #
  # Body content: welcome / invitation / new_password / notification render
  # Liquid from EmailTemplate (DB row or app/views/email_templates/defaults);
  # new_nation / new_change_vote render their html.erb templates.

  def new_nation(govt, user)
    @govt = govt
    @user = user
    mail(:to => "#{user.login} <#{user.email}>",
         :from => "Jim Gilliam <jim@gilliam.com>",
         :reply_to => "jim@gilliam.com",
         :subject => "Your nation is ready")
  end

  def welcome(user)
    @user = user
    govt = Government.current
    locals = { 'government' => govt, 'user' => user }
    body = liquid_body("welcome", locals)
    mail(:to => recipient_for(user),
         :from => notification_from,
         :reply_to => govt.admin_email,
         :subject => liquid_subject("welcome", locals)) do |format|
      format.text { render :plain => body }
    end
  end

  def invitation(user, sender_name, to_name, to_email)
    to = ""
    to += to_name + ' ' if to_name
    to += '<' + to_email + '>'
    locals = { 'government' => Government.current, 'user' => user, 'sender_name' => sender_name,
               'to_name' => to_name, 'to_email' => to_email }
    body = liquid_body("invitation", locals)
    mail(:to => to,
         :from => notification_from,
         :reply_to => Government.current.admin_email,
         :subject => liquid_subject("invitation", locals)) do |format|
      format.text { render :plain => body }
    end
  end

  def new_password(user, new_password)
    setup_notification(user)
    locals = { 'government' => Government.current, 'user' => user, 'new_password' => new_password }
    body = liquid_body("new_password", locals)
    mail(:to => recipient_for(user),
         :from => notification_from,
         :reply_to => Government.current.email,
         :subject => liquid_subject("new_password", locals)) do |format|
      format.text { render :plain => body }
    end
  end

  def notification(n, sender, recipient, notifiable)
    setup_notification(recipient)
    name = n.class.to_s.underscore
    locals = { 'government' => Government.current, 'recipient' => recipient, 'sender' => sender,
               'notifiable' => notifiable, 'notification' => n }
    body = liquid_body(name, locals)
    mail(:to => recipient_for(recipient),
         :from => notification_from,
         :reply_to => Government.current.email,
         :subject => liquid_subject(name, locals)) do |format|
      format.text { render :plain => body }
    end
  end

  def new_change_vote(sender, recipient, vote)
    setup_notification(recipient)
    @sender = sender
    @recipient = recipient
    @vote = vote
    @change = vote.change
    mail(:to => recipient_for(recipient),
         :from => notification_from,
         :reply_to => Government.current.email,
         :subject => "Your #{Government.current.name} vote is needed: #{vote.change.priority.name}")
  end

  protected

  def setup_notification(user)
    @recipient = user
    @root_url = 'http://' + Government.current.base_url + '/'
  end

  def notification_from
    "#{Government.current.name} <#{Government.current.email}>"
  end

  def recipient_for(user)
    "#{user.real_name.titleize} <#{user.email}>"
  end

  def liquid_subject(name, locals)
    EmailTemplate.fetch_subject_liquid(name).render(locals, :filters => [LiquidFilters])
  end

  def liquid_body(name, locals)
    EmailTemplate.fetch_liquid(name).render(locals, :filters => [LiquidFilters])
  end

end
