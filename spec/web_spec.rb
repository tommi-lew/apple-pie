require 'spec_helper'

describe 'Sinatra Application' do
  def app
    Sinatra::Application
  end

  describe 'GET /' do
    it "says '200'" do
      get '/'
      expect(last_response.body).to eq('200')
    end
  end

  describe 'POST /pt_activity_web_hook' do
    context 'pivotal tracker activity' do
      describe 'kind is not comment_create_activity' do
        it 'logs and stop request' do
          expect_any_instance_of(Sinatra::Application).to receive(:log).with('Do not handle this activity.')

          post '/pt_activity_web_hook', { kind: 'random_activity' }.to_json

          expect(last_response.status).to eq(200)
        end
      end

      context 'appropriate text not found' do
        it 'logs and stop request' do
          expect_any_instance_of(Sinatra::Application).to receive(:log).with('No further action.')

          post '/pt_activity_web_hook', { kind: 'comment_create_activity', text: 'quick brown fox' }.to_json

          expect(last_response.status).to eq(200)
        end
      end
    end

    context 'pull request' do
      before do
        @github = double('Github')
        @pull_requests_ns = double('Pull Request Namespace')
        expect(Github).to receive(:new).and_return(@github)
      end

      it 'looks for a matching pull request based on the pivotal tracker story id' do
        pull_requests = []
        pull_requests << instance_double('pull_request', title: '[#22222222] Story 2')
        pull_requests << instance_double('pull_request', title: '[#11111111] Story 1')

        expect(@github).to receive(:pull_requests).and_return(@pull_requests_ns)
        expect(@pull_requests_ns).to receive(:list).and_return(pull_requests)

        post '/pt_activity_web_hook', { kind: 'comment_create_activity', id: 11111111, text: 'ui ok' }.to_json
      end

      describe 'pull request not found' do
        it 'logs and stop request' do
          expect_any_instance_of(Sinatra::Application).to receive(:log).with('No further action.')

          pull_requests = []

          expect(@github).to receive(:pull_requests).and_return(@pull_requests_ns)
          expect(@pull_requests_ns).to receive(:list).and_return(pull_requests)

          post '/pt_activity_web_hook', { kind: 'comment_create_activity', id: 11111111, text: 'ui ok' }.to_json

          expect(last_response.status).to eq(200)
        end
      end

      it 'updates pull request' do
        ENV['GITHUB_USER'] = 'github_user'
        ENV['GITHUB_REPO'] = 'github_repo'

        pull_request = instance_double('pull_request', title: '11111111', number: 1, body: '')
        pull_requests = [pull_request]

        expect(@github).to receive(:pull_requests).and_return(@pull_requests_ns).twice
        expect(@pull_requests_ns).to receive(:list).and_return(pull_requests)
        expect(@pull_requests_ns).to receive(:update).with('github_user', 'github_repo', 1, body: update_ui_status(''))

        post '/pt_activity_web_hook', { kind: 'comment_create_activity', id: 11111111, text: 'ui ok' }.to_json
      end
    end
  end

  describe '#ui_approval_text?' do
    it 'determines text indicates approval of ui' do
      expect(ui_approval_text?('ui ok')).to be_truthy
      expect(ui_approval_text?('I have updated...')).to be_falsey
    end
  end

  describe '#update_ui_status' do
    it 'returns text with updated ui status' do
      original_pr_body = <<-EOS.gsub(/^\s+/, '')
        Hello world. This pull request is about

        ********************UI STATUS********************
        UI pending
        ***********DO NOT ADD TEXT BELOW HERE************
      EOS

      expected_pr_body = <<-EOS.gsub(/^\s+/, '')
        Hello world. This pull request is about

        ********************UI STATUS********************
        UI :)
        ***********DO NOT ADD TEXT BELOW HERE************
      EOS

      expect(update_ui_status(original_pr_body)).to eq(expected_pr_body)
    end

    context 'pull request body does not contain ui status' do
      it 'adds ui status' do
        original_pr_body = 'Hello world. This pull request is about'

        expected_pr_body = original_pr_body + "\n"
        expected_pr_body += <<-EOS.gsub(/^\s+/, '')
          ********************UI STATUS********************
          UI :)
          ***********DO NOT ADD TEXT BELOW HERE************
        EOS

        expect(update_ui_status(original_pr_body)).to eq(expected_pr_body)
      end
    end
  end
end
