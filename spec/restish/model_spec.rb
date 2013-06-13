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
end

class TheTestModel < Restish::Model
end

class DaTestModel < Restish::Model
end

describe Restish::Model do
  it "extends the model class with specific repository" do
    TheTestModel.foo.should eq 'bar'
  end

  it "pushes the class into Repository.repositories" do
    Restish::Repository.repositories.should include(TheTestModel)
  end

  it "extends the model class with repository" do
    DaTestModel.should be_kind_of(Restish::Repository)
  end

  it "contains error messages" do
    TheTestModel.new.errors.should be_a(Restish::Errors)
  end

end
