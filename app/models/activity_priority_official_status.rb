class ActivityPriorityOfficialStatus < Activity
  def sentence
    "marked this priority as #{priority&.official_status_name}"
  end
  def icon = "⚑"
end
