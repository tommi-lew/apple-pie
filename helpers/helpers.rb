def ui_approval_text?(text)
  !!(text =~ /ui ok/)
end

def update_ui_status(pull_request_body, status)
  ui_status_header = "********************UI STATUS********************"
  ui_status_index = pull_request_body.index(ui_status_header)

  status_emoji = case status
                   when :ok
                     ':+1:'
                   when :pending
                     ':hand:'
                 end

  pr_body_without_ui_status = if ui_status_index
                                pull_request_body[0..ui_status_index - 1].gsub(/$\s+/, '')
                              else
                                pull_request_body
                              end

  pr_body_without_ui_status += "\n\n"
  pr_body_without_ui_status += <<-EOS.gsub(/^\s+/, '')
    ********************UI STATUS********************
    #{status_emoji}
    Updated at #{Time.now}
    ***********DO NOT ADD TEXT BELOW HERE************
  EOS

  pr_body_without_ui_status
end