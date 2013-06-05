require 'spec_helper'

module TheTestModelRepository
  def foo
    'bar'
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
end
