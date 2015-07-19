class ApplePie < Sinatra::Base
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

    updated_pull_request_body = update_status(body, :ui, :pending)

    response = github.pull_requests.update(
        ENV['GITHUB_USER'],
        ENV['GITHUB_REPO'],
        pr_number,
        body: updated_pull_request_body
    )

    logger.info "Pull request update response status: #{response.status}"

    halt
  end
end