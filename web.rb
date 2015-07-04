require_relative File.join('config', 'shared.rb')

get '/' do
  '200'
end

post '/pt_activity_web_hook' do
  kind = params['kind']
  story_id = params['id']
  text = params['text']

  if !kind.eql?('comment_create_activity')
    respond_with_json({ message: 'Do not handle this activity.' })
  end

  if !ui_approval_text?(text)
    respond_with_json({ message: 'No further action.' })
  end

  github = Github.new(user: ENV['GITHUB_USER'], repo: ENV['GITHUB_REPO'])
  pull_requests = github.pull_requests.list
  pull_request = pull_requests.find{|pr| pr.title[/#{story_id}/] }

  if !pull_request
    respond_with_json({ message: 'No further action.' })
  end

  updated_pull_request_body = update_ui_status(pull_request.body)

  github.pull_requests.update(
    ENV['GITHUB_USER'],
    ENV['GITHUB_REPO'],
    pull_request.number,
    body: updated_pull_request_body
  )

  halt
end

def respond_with_json(response)
  halt response.to_json
end

def ui_approval_text?(text)
  !!(text =~ /ui ok/)
end

def update_ui_status(pull_request_body)
  ui_status_header = "********************UI STATUS********************"
  ui_status_index = pull_request_body.index(ui_status_header)

  pr_body_without_ui_status = if ui_status_index
                                pull_request_body[0..ui_status_index - 1].gsub(/$\s+/, '')
                              else
                                pull_request_body
                              end

  pr_body_without_ui_status += "\n"
  pr_body_without_ui_status += <<-EOS.gsub(/^\s+/, '')
    ********************UI STATUS********************
    UI :)
    ***********DO NOT ADD TEXT BELOW HERE************
  EOS

  pr_body_without_ui_status
end