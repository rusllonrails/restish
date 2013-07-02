require 'spec_helper'
require 'ostruct'

class TestRepository < Restish::Repository
end

class Test < Restish::Model
end

describe Restish::Repository do
  let(:repository) { TestRepository.new }

  describe '.for' do
    it 'instantiates a repository for a model' do
      Restish::Repository.for('Test').should be_kind_of(TestRepository)
    end
  end

  describe '#all' do
    let(:test_adapter) { mock 'TestAdapter', all: [] }

    it 'fetches all models from adapter' do
      repository.should_receive(:adapter).with('test')
        .and_return test_adapter
      repository.all.should eq []
    end
  end

  describe '#find' do
    context 'given the model is not found locally' do
      before do
        repository.stub(:find_locally).and_return nil
      end

      let(:model)        { mock 'Model' }
      let(:test_adapter) { mock 'TestAdapter', find: model }

      it 'fetches the model from adapter' do
        repository.should_receive(:adapter).with('test')
          .and_return test_adapter
        test_adapter.should_receive(:find).with 123, {}
        repository.find(123).should eq model
      end
    end

    context 'given the model is found locally' do
      before do
        repository.stub(:find_locally).and_return model
      end

      let(:model)        { mock 'Model' }

      it 'returns the local model' do
        repository.find(123).should eq model
      end
    end
  end

  describe '#find_locally' do
    context 'given the model is present in @all' do
      let(:model)        { mock 'Model', id: 123 }

      it 'it returns the model' do
        repository.instance_variable_set(:@all, [model])
        repository.find_locally(123).should eq model
      end
    end

    context 'given the model is not present in @all' do
      let(:model)        { mock 'Model' }

      it 'it returns nil' do
        repository.instance_variable_set(:@all, [])
        repository.find_locally(123).should be_nil
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
      repository.stub(:all).and_return categories
    end

    context 'query with 1 key-value' do
      it 'filters all models from adapter' do
        repository.filter(parent_id: 1).size.should eq 1
        repository.filter(parent_id: 1).first.id.should eq 2
      end
    end

    context 'query with 2 key-values' do
      it 'filters all models from adapter using AND logic' do
        filtered = repository.filter(parent_id: 2, extra: true)
        filtered.size.should eq 1
        filtered.first.id.should eq 3
      end
    end
  end

  context '#save' do
    let(:test_adapter) { mock 'TestAdapter' }
    let(:remote_model) { Test.new(name: 'Helga') }
    let(:model) { Test.new }

    context 'with valid model' do
      it 'creates not persisted record' do
        repository.should_receive(:adapter).and_return(test_adapter)
        test_adapter.should_receive(:create).and_return(remote_model)
        result = repository.save(model)
        result.should eq true
      end

      it 'do not create persisted record' do
        model.id = 1
        test_adapter.should_not_receive(:create)
        repository.save(model)
      end

      it 'updates model attributes' do
        repository.should_receive(:adapter).and_return(test_adapter)
        test_adapter.should_receive(:create).and_return(remote_model)
        repository.save(model)
        model.name.should eq 'Helga'
      end
    end

    context "with invalid model" do
      let(:error_messages) { { 'name' => ["can't be blank"], 'email' => ['has already been taken', 'is invalid'] } }
      let(:response) { mock 'Response', status: 422, body: { 'errors' => error_messages } }
      let(:model) { Test.new(name: '33') }

      before do
        repository.should_receive(:adapter).and_return(test_adapter)
        test_adapter.should_receive(:create).and_raise(Restish::Adapter::UnprocessableEntityError.new(response))
      end

      it "returns false" do
        result = repository.save(Test.new)
        result.should eq false
      end

      it "populates errors" do
        repository.save(model)
        model.errors.should_not be_blank
        model.errors[:base].join(' ').should include('is invalid')
        error_messages['name'].each do |message|
          model.errors['name'].should include(message)
        end
      end
    end
  end

  context '#update' do
    let(:test_adapter) { mock 'TestAdapter' }
    let(:remote_model) { Test.new(id: 3, name: 'Olga') }
    let(:model) { Test.new(id: 3, name: 'Helga') }

    context 'with valid model' do
      it 'returns status' do
        repository.should_receive(:adapter).and_return(test_adapter)
        test_adapter.should_receive(:update).and_return(remote_model)
        result = repository.update(model, name: 'Olga')
        result.should eq true
      end

      it 'updates model attributes' do
        repository.should_receive(:adapter).and_return(test_adapter)
        test_adapter.should_receive(:update).and_return(remote_model)
        repository.update(model, name: 'Olga')
        model.name.should eq 'Olga'
      end

    end

    context "with invalid model" do
      let(:error_messages) { { 'name' => ["can't be blank"], 'email' => ['has already been taken', 'is invalid'] } }
      let(:response) { mock 'Response', status: 422, body: { 'errors' => error_messages } }
      let(:model) { Test.new(id: 33, name: '33') }

      before do
        repository.should_receive(:adapter).and_return(test_adapter)
        test_adapter.should_receive(:update).and_raise(Restish::Adapter::UnprocessableEntityError.new(response))
      end

      it "returns false" do
        result = repository.update(model, name: '', email: 'olga@example.com')
        result.should eq false
      end

      it "populates errors" do
        repository.update(model, name: '', email: 'olga@example.com')
        model.errors.should_not be_blank
        model.errors[:base].join(' ').should include('is invalid')
        error_messages['name'].each do |message|
          model.errors['name'].should include(message)
        end
      end
    end
  end

end

