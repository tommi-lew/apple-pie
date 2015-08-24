def status_from_text(text)
  result = {}

  if text.include?('ui ok')
    result[:ui]= :ok
  end

  if text.include?('feature ok')
    result[:feature] = :ok
  end

  if text.include?('ui un-ok')
    result[:ui] = :pending
  end

  if text.include?('feature un-ok')
    result[:feature] = :pending
  end

  result
end

def statuses_header
  '~~~~~ Statuses ~~~~~'
end

def statuses_footer
  '~~~~~  do not add text below ~~~~~'
end

def status_to_emoji(status)
  case status
    when :pending
      ':hand:'
    when :ok
      ':+1:'
  end
end

def emoji_to_status(emoji)
  case emoji
    when ':hand:'
      :pending
    when ':+1:'
      :ok
  end
end

def parse_statuses(pull_request_body)
  ui = :pending
  feature = :pending

  header_index = pull_request_body.index(statuses_header)
  footer_index = pull_request_body.index(statuses_footer)

  if header_index.nil?
    return { ui: ui, feature: feature }
  end

  statuses_text = pull_request_body[header_index..footer_index]

  statuses_text.each_line do |line|
    if line.start_with?('UI ')
      line.slice!('UI ')
      line.chomp!
      ui = emoji_to_status(line)
    elsif line.start_with?('Feature ')
      line.slice!('Feature ')
      line.chomp!
      feature = emoji_to_status(line)
    end
  end

  { ui: ui, feature: feature }
end

def update_status(pull_request_body, updated_statuses)
  ui_status_index = pull_request_body.index(statuses_header)

  statuses = parse_statuses(pull_request_body)
  statuses.merge!(updated_statuses)

  pr_body_with_new_statuses = if ui_status_index
                                pull_request_body[0..ui_status_index - 1].gsub(/$\s+/, '')
                              else
                                pull_request_body
                              end

  pr_body_with_new_statuses += "\n\n"
  pr_body_with_new_statuses += <<-EOS.gsub(/^\s+/, '')
    #{statuses_header}
    UI #{status_to_emoji(statuses[:ui])}
    Feature #{status_to_emoji(statuses[:feature])}
    Updated #{Time.now}
    #{statuses_footer}
  EOS

  pr_body_with_new_statuses
end