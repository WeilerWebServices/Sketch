# frozen_string_literal: true

require_relative './spec_helper'

# Note: Those tests will create and delete records and indexes several time.

# rubocop:disable Metrics/BlockLength
describe('storing object ids') do
  let(:logger) { Jekyll::Algolia::Logger }
  let(:configurator) { Jekyll::Algolia::Configurator }
  let(:indexer) { Jekyll::Algolia::Indexer.init }
  let(:progress_bar) { Jekyll::Algolia::ProgressBar }
  let(:progress_bar_instance) { double('ProgressBar').as_null_object }
  let(:records) do
    [
      { objectID: 'foo', name: 'foo' },
      { objectID: 'bar', name: 'bar' },
      { objectID: 'baz', name: 'baz' }
    ]
  end

  before do
    allow(configurator)
      .to receive(:algolia)
      .and_call_original
    allow(configurator)
      .to receive(:algolia)
      .with('application_id')
      .and_return(ENV['ALGOLIA_APPLICATION_ID'])
    allow(configurator)
      .to receive(:algolia)
      .with('api_key')
      .and_return(ENV['ALGOLIA_API_KEY'])
    allow(configurator)
      .to receive(:algolia)
      .with('index_name')
      .and_return(ENV['ALGOLIA_INDEX_NAME'])
    allow(logger).to receive(:log)
    allow(progress_bar).to receive(:create).and_return(progress_bar_instance)

    indexer.index.delete_index!
    indexer.index_object_ids.delete_index!
  end

  describe 'initial push should store ids in dedicated index' do
    before do
      indexer.update_records(records)
      @index = indexer.index_object_ids
    end

    it 'should create a dedicated index' do
      has_dedicated_index = indexer.index_exist?(@index)
      expect(has_dedicated_index).to eq true
    end

    it 'should contain all object ids' do
      records = @index.search('')['hits']
      expect(records.length).to eq 1
      expect(records[0]['content']).to include('foo')
      expect(records[0]['content']).to include('bar')
      expect(records[0]['content']).to include('baz')
    end
  end

  describe 'dedicated index should be created if does not exist' do
    before do
      indexer.update_records(records)
      indexer.index_object_ids.delete_index!
      indexer.update_records(records)
      @index = indexer.index_object_ids
    end

    it 'should create a dedicated index' do
      has_dedicated_index = indexer.index_exist?(@index)
      expect(has_dedicated_index).to eq true
    end

    it 'should contain all object ids' do
      records = @index.search('')['hits']
      expect(records.length).to eq 1
      expect(records[0]['content']).to include('foo')
      expect(records[0]['content']).to include('bar')
      expect(records[0]['content']).to include('baz')
    end
  end

  describe 'clearing the main index should force its recreation' do
    before do
      indexer.update_records(records)
      indexer.index.clear_index!
      indexer.update_records(records)
      @index = indexer.index
    end

    it 'should recreate the main index' do
      has_index = indexer.index_exist?(@index)
      expect(has_index).to eq true
    end

    it 'should contain all hits' do
      records = @index.search('')['hits']
      expect(records.length).to eq 3
    end
  end
end
# rubocop:enable Metrics/BlockLength
