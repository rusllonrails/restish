require 'spec_helper'

module TheTestModelRepository
  include Restish::Repository
  def foo
    'bar'
  end
end

class TheTestModelAdapter < Restish::Adapter
  def create(model)
    model.id = 3
    model
  end

  def update(model, attributes = {})
    TheTestModel.new(model.merge(attributes))
  end
end

class TheTestModel < Restish::Model
end

class DaTestModel < Restish::Model
end

describe Restish::Model do
  it 'extends the model class with specific repository' do
    TheTestModel.foo.should eq 'bar'
  end

  it 'pushes the class into Repository.repositories' do
    Restish::Repository.repositories.should include(TheTestModel)
  end

  it 'extends the model class with repository' do
    DaTestModel.should be_kind_of(Restish::Repository)
  end

  it 'contains error messages' do
    TheTestModel.new.errors.should be_a(Restish::Errors)
  end

  it 'can be transformed to param' do
    TheTestModel.new(id: 3).to_param.should eq 'id=3'
  end

  its 'attributes can be updated' do
    model = TheTestModel.new(id: 3, name: 'Helga')
    model.update_attributes(name: 'Olga').should eq true
    model.name.should eq 'Olga'
  end

  it 'can be saved' do
    model = TheTestModel.new
    expect { model.save }.to change { model.persisted? }
    model.save.should eq true
  end
end
