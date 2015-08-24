require 'spec_helper'

describe 'Helpers' do
  describe '#status_from_text' do
    it 'returns types and their statuses' do
      text = 'ui ok feature ok'
      expect(status_from_text(text)).
          to eq(ui: :ok, feature: :ok)

      text = 'ui un-ok feature un-ok'
      expect(status_from_text(text)).
          to eq(ui: :pending, feature: :pending)
    end

    context 'conflicting status for the same type' do
      it 'will always be pending' do
        text = 'ui un-ok ui ok'
        expect(status_from_text(text)).
            to eq(ui: :pending)

        text = 'feature un-ok feature ok'
        expect(status_from_text(text)).
            to eq(feature: :pending)
      end
    end
  end

  describe '#statuses_header' do
    it 'returns statuses header string' do
      expect(statuses_header).to eq('~~~~~ Statuses ~~~~~')
    end
  end

  describe '#statuses_footer' do
    it 'returns statuses header string' do
      expect(statuses_footer).to eq('~~~~~  do not add text below ~~~~~')
    end
  end

  describe '#state_to_emoji' do
    it 'returns emoji according to state' do
      expect(status_to_emoji(:pending)).to eq(':hand:')
      expect(status_to_emoji(:ok)).to eq(':+1:')
    end
  end

  describe '#emoji_to_state' do
    it 'returns emoji according to state' do
      expect(emoji_to_status(':hand:')).to eq(:pending)
      expect(emoji_to_status(':+1:')).to eq(:ok)
    end
  end

  describe '#parse_statuses' do
    it 'return statuses' do
      pr_body = <<-EOS.gsub(/^\s+/, '')
        ~~~~~ Statuses ~~~~~
        UI :hand:
        Feature :hand:
        Updated #{Time.now}
        ~~~~~  do not add text below ~~~~~
      EOS

      expect(parse_statuses(pr_body)).to eq({ ui: :pending, feature: :pending })


      pr_body = <<-EOS.gsub(/^\s+/, '')
        ~~~~~ Statuses ~~~~~
        UI :+1:
        Feature :+1:
        Updated #{Time.now}
        ~~~~~  do not add text below ~~~~~
      EOS

      expect(parse_statuses(pr_body)).to eq({ ui: :ok, feature: :ok })
    end

    context 'statuses text does not exist' do
      it 'returns statuses' do
        expect(parse_statuses('')).to eq({ ui: :pending, feature: :pending })
      end
    end
  end

  describe '#update_status' do
    it 'returns text with updated ui status' do
      Timecop.freeze

      updated_statuses = status_from_text('ui ok feature ok')

      original_pr_body = "Hello world. This pull request is about\n\n"
      original_pr_body += <<-EOS.gsub(/^\s+/, '')
        ~~~~~ Statuses ~~~~~
        UI :hand:
        Feature :hand:
        Updated #{Time.now}
        ~~~~~  do not add text below ~~~~~
      EOS

      expected_pr_body = "Hello world. This pull request is about\n\n"
      expected_pr_body += <<-EOS.gsub(/^\s+/, '')
        ~~~~~ Statuses ~~~~~
        UI :+1:
        Feature :+1:
        Updated #{Time.now}
        ~~~~~  do not add text below ~~~~~
      EOS

      expect(update_status(original_pr_body, updated_statuses)).to eq(expected_pr_body)
    end

    context 'pull request body does not contain status text' do
      it 'adds statuses' do
        updated_statuses = status_from_text('feature ok')
        original_pr_body = 'Hello world. This pull request is about'

        expected_pr_body = original_pr_body + "\n\n"
        expected_pr_body += <<-EOS.gsub(/^\s+/, '')
          ~~~~~ Statuses ~~~~~
          UI :hand:
          Feature :+1:
          Updated #{Time.now}
          ~~~~~  do not add text below ~~~~~
        EOS

        expect(update_status(original_pr_body, updated_statuses)).to eq(expected_pr_body)
      end
    end
  end
end