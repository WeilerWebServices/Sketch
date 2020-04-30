# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
require 'spec_helper'

describe(Jekyll::Algolia::Logger) do
  let(:current) { Jekyll::Algolia::Logger }
  let(:configurator) { Jekyll::Algolia::Configurator }
  describe '.known_message' do
    let(:io) { double('IO', read: content) }
    let(:content) { "I: Info line {index_name}\nW: Warning line" }
    let(:metadata) { { 'index_name' => 'my_index' } }

    before do
      allow(File)
        .to receive(:open)
        .and_return(io)
      allow(current).to receive(:log)
    end

    before { current.known_message('custom_message', metadata) }

    it do
      expect(File)
        .to have_received(:open)
        .with(/custom_message\.txt$/)
      expect(current).to have_received(:log).with('I: Info line my_index')
      expect(current).to have_received(:log).with('W: Warning line')
    end

    context 'with non-string metadata' do
      describe do
        let(:metadata) { { 'index_name' => false } }
        it do
          expect(current).to have_received(:log).with('I: Info line false')
        end
      end

      describe do
        let(:metadata) { { 'index_name' => %w[foo bar] } }
        it do
          expect(current)
            .to have_received(:log)
            .with('I: Info line ["foo", "bar"]')
        end
      end
    end
  end

  describe '.log' do
    context 'with an error line' do
      let(:input) { 'E: Error line' }
      before do
        expect(Jekyll.logger)
          .to receive(:error)
          .with(/Error line/)
      end
      it { current.log(input) }
    end
    context 'with a warning line' do
      let(:input) { 'W: Warning line' }
      before do
        expect(Jekyll.logger)
          .to receive(:warn)
          .with(/Warning line/)
      end
      it { current.log(input) }
    end
    context 'with an information line' do
      let(:input) { 'I: Information line' }
      before do
        expect(Jekyll.logger)
          .to receive(:info)
          .with(/Information line/)
      end
      it { current.log(input) }
    end

    context 'with regular type' do
      let(:input) { 'I: Information line' }
      before do
        expect(Jekyll.logger)
          .to receive(:info)
          .with(/^.{80,80}$/)
      end
      it { current.log(input) }
    end

    context 'with an new line' do
      let(:input) { "I:\nInformation line" }
      before do
        allow(Jekyll.logger).to receive(:info)
        expect(Jekyll.logger)
          .to receive(:info)
          .with(/Information line/)
      end
      it { current.log(input) }
    end
  end

  describe '.verbose' do
    before do
      allow(configurator).to receive(:verbose?).and_return(is_verbose)
    end
    before { allow(current).to receive(:log) }
    before { current.verbose('foo') }

    context 'when verbose is disabled' do
      let(:is_verbose) { false }
      it do
        expect(current)
          .to_not have_received(:log)
          .with('foo')
      end
    end
    context 'when verbose is enabled' do
      let(:is_verbose) { true }
      it do
        expect(current)
          .to have_received(:log)
          .with('foo')
      end
    end
  end

  describe '.write_to_file' do
    let(:filename) { 'output.log' }
    let(:content) { 'content' }
    let(:source) { '/source/' }

    before do
      expect(configurator)
        .to receive(:get).with('source').and_return(source)
      expect(File).to receive(:write)
        .with('/source/output.log', content)
    end

    subject { current.write_to_file(filename, content) }

    it { should eq '/source/output.log' }
  end
end
# rubocop:enable Metrics/BlockLength
