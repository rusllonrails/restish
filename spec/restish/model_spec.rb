require 'spec_helper'

class TheTestModelRepository < Restish::Repository
  def foo
    'bar'
  end
end

class TheTestModelAdapter < Restish::Adapter
  def create(model)
    model.id = 3
    model
  end

  def update(model)
    TheTestModel.new(model)
  end
end

class TheTestModel < Restish::Model
  attributes :name, :company
end

class DaTestModel < Restish::Model
end

describe Restish::Model do
  it 'set up repository on initialization' do
    repo = TheTestModel.new.instance_eval { @_repository }
    repo.should be_kind_of(TheTestModelRepository)
  end

  it 'contains error messages' do
    TheTestModel.new.errors.should be_a(Restish::Errors)
  end

  it 'can be transformed to param' do
    TheTestModel.new(id: 3).to_param.should eq 'id=3'
  end

  context '.attributes' do
    it 'makes accessible list of attributes' do
      TheTestModel.attributes.should include(:name, :company)
    end

    it 'decorate accessors for ActiveModel::Dirty' do
      model = TheTestModel.new
      model.name = 'Bob'
      model.changed.should include('name')
    end
  end

  context '#update_attributes' do
    let(:model) { TheTestModel.new(id: 3, name: 'Helga') }

    it 'updates attributes' do
      model.update_attributes(name: 'Olga').should eq true
      model.name.should eq 'Olga'
    end

    it 'calls a repository for saving' do
      repository = model.instance_variable_get(:@_repository)
      repository.should_receive(:save)
      model.update_attributes(name: 'Olga')
    end
  end

  context '#save' do
    it 'calls a repository' do
      model = TheTestModel.new
      repository = model.instance_variable_get(:@_repository)
      repository.should_receive(:save)
      model.save
    end
  end

end
