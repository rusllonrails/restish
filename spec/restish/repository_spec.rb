require 'spec_helper'
require 'ostruct'

class TestRepository
  extend Restish::Repository
end

class TestModel < Restish::Model
end

describe Restish::Repository do
  describe '.repository' do
    it 'is initialized to array' do
      Restish::Repository.repositories.should be_kind_of Array
    end
  end

  describe '.extended' do
    it 'pushes the class into repositories' do
      Restish::Repository.repositories.should include TestRepository
      Restish::Repository.repositories.should include TestModel
    end
  end

  describe '.clear_cache' do
    before do
      @old_repositires = Restish::Repository.repositories
    end

    after do
      Restish::Repository.repositories = @old_repositires
    end

    it 'pushes the class into repositories' do
      repository1 = mock 'Repository', clear_cache: nil
      repository2 = mock 'Repository', clear_cache: nil
      repository1.should_receive :clear_cache
      repository2.should_receive :clear_cache
      Restish::Repository.repositories = [repository1, repository2]
      Restish::Repository.clear_cache
    end
  end

  describe '#clear_cache' do
    it 'clears memoized value @all' do
      TestRepository.instance_variable_set :@all, 'yeehaw'
      TestRepository.clear_cache
      TestRepository.instance_variable_get(:@all).should be_nil
    end
  end

  describe '#all' do
    let(:test_adapter) { mock 'TestAdapter', all: [] }

    context 'included in repository' do
      it 'fetches all models from adapter' do
        TestRepository.should_receive(:adapter).with('test')
          .and_return test_adapter
        TestRepository.all.should eq []
      end
    end

    context 'included in model' do
      it 'resolves model name correctly' do
        TestModel.should_receive(:adapter).with('test_model')
          .and_return test_adapter
        TestModel.all
      end
    end
  end

  describe '#find' do
    context 'given the model is not found locally' do
      before do
        TestRepository.stub(:find_locally).and_return nil
      end

      let(:model)        { mock 'Model' }
      let(:test_adapter) { mock 'TestAdapter', find: model }

      it 'fetches the model from adapter' do
        TestRepository.should_receive(:adapter).with('test')
          .and_return test_adapter
        test_adapter.should_receive(:find).with 123, {}
        TestRepository.find(123).should eq model
      end
    end

    context 'given the model is found locally' do
      before do
        TestRepository.stub(:find_locally).and_return model
      end

      let(:model)        { mock 'Model' }

      it 'returns the local model' do
        TestRepository.find(123).should eq model
      end
    end
  end

  describe '#find_locally' do
    context 'given the model is present in @all' do
      let(:model)        { mock 'Model', id: 123 }

      it 'it returns the model' do
        TestRepository.instance_variable_set(:@all, [model])
        TestRepository.find_locally(123).should eq model
      end
    end

    context 'given the model is not present in @all' do
      let(:model)        { mock 'Model' }

      it 'it returns nil' do
        TestRepository.instance_variable_set(:@all, [])
        TestRepository.find_locally(123).should be_nil
      end
    end
  end

  describe '#filter' do
    let(:categories) do
      [OpenStruct.new(id: 1, parent_id: nil),
        OpenStruct.new(id: 2, parent_id: 1),
        OpenStruct.new(id: 3, parent_id: 2, extra: true),
        OpenStruct.new(id: 4, parent_id: 2)]
    end

    before do
      TestRepository.stub(:all).and_return categories
    end

    context 'query with 1 key-value' do
      it 'filters all models from adapter' do
        TestRepository.filter(parent_id: 1).size.should eq 1
        TestRepository.filter(parent_id: 1).first.id.should eq 2
      end
    end

    context 'query with 2 key-values' do
      it 'filters all models from adapter using AND logic' do
        filtered = TestRepository.filter(parent_id: 2, extra: true)
        filtered.size.should eq 1
        filtered.first.id.should eq 3
      end
    end
  end

  context '#save' do
    let(:test_adapter) { mock 'TestAdapter' }
    let(:remote_model) { TestModel.new(name: 'Helga') }
    let(:model) { TestModel.new }

    context "with valid model" do
      before do
        TestRepository.should_receive(:adapter).and_return(test_adapter)
        test_adapter.should_receive(:create).and_return(remote_model)
      end

      it "creates not persisted record" do
        result = TestRepository.save(model)
        result.should eq true
      end

      it "updates model attributes" do
        TestRepository.save(model)
        model.name.should eq 'Helga'
      end
    end

    context "with invalid model" do
      let(:error_messages) { { 'name' => ["can't be blank"], 'email' => ['has already been taken', 'is invalid'] } }
      let(:response) { mock 'Response', status: 422, body: { 'errors' => error_messages } }
      let(:model) { TestModel.new(name: '33') }

      before do
        TestRepository.should_receive(:adapter).and_return(test_adapter)
        test_adapter.should_receive(:create).and_raise(Restish::Adapter::UnprocessableEntityError.new(response))
      end

      it "returns false" do
        result = TestRepository.save(TestModel.new)
        result.should eq false
      end

      it "populates errors" do
        TestRepository.save(model)
        model.errors.should_not be_blank
        model.errors[:base].join(' ').should include('is invalid')
        error_messages['name'].each do |message|
          model.errors['name'].should include(message)
        end
      end
    end
  end
end

