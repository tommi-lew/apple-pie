require_relative File.join('config', 'shared.rb')

get '/' do
  '200'
end

post '/pt_activity_web_hook' do
  request_body = request.body.read
  json_request_body = JSON.parse(request_body)

  logger.info request_body

  kind = json_request_body['kind']
  story_id = (json_request_body['primary_resources']) ? json_request_body['primary_resources'][0]['id'] : nil
  text = (json_request_body['changes']) ? json_request_body['changes'][0]['new_values']['text'] : nil

  if !kind.eql?('comment_create_activity')
    logger.info 'Do not handle this activity.'
    halt
  end

  if !ui_approval_text?(text)
    logger.info 'No further action, ui approval text not found.'
    halt
  end

  logger.info "PT Story ID: #{story_id}"

  github = Github.new(user: ENV['GITHUB_USER'], repo: ENV['GITHUB_REPO'])
  pull_requests = github.pull_requests.list
  pull_request = pull_requests.find{|pr| !!pr.title.index(story_id.to_s) }

  if !pull_request
    logger.info 'No further action, no matching pull requests.'
    halt
  end

  updated_pull_request_body = update_ui_status(pull_request.body, :ok)

  logger.info "PR title: #{pull_request.title}"
  logger.info "PR number: #{pull_request.number}"
  logger.info "PR current body: #{pull_request.body}"

  response = github.pull_requests.update(
    ENV['GITHUB_USER'],
    ENV['GITHUB_REPO'],
    pull_request.number,
    body: updated_pull_request_body
  )

  logger.info "Pull request update response status: #{response.status}"

  halt
end

post '/gh_webhook' do
  request_body = request.body.read
  json_request_body = JSON.parse(request_body)

  logger.info request_body

  action = json_request_body['action']
  pr_number = json_request_body['number']
  body = (json_request_body['pull_request']) ? json_request_body['pull_request']['body'] : nil

  if !action.eql?('opened')
    logger.info 'Do not handle this action.'
    halt
  end

  github = Github.new(user: ENV['GITHUB_USER'], repo: ENV['GITHUB_REPO'])

  updated_pull_request_body = update_ui_status(body, :pending)

  response = github.pull_requests.update(
      ENV['GITHUB_USER'],
      ENV['GITHUB_REPO'],
      pr_number,
      body: updated_pull_request_body
  )

  logger.info "Pull request update response status: #{response.status}"

  halt
end

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

