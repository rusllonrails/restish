require 'restish/repository_wrapper'
require 'restish/repository'
require 'restish/model'

describe Restish::RepositoryWrapper do

  SomeModelRepository = Class.new(Restish::Repository)
  SomeModel = Class.new(Restish::Model)
  NotModel = Class.new
  
  let(:model_class) { Class.new(Restish::Model) { extend Restish::RepositoryWrapper } }
  let(:repository) { Class.new(Restish::Repository) }

  it 'is extended only by Restish::Model' do
    expect { NotModel.extend Restish::RepositoryWrapper }.to raise_error
  end

  context '.repository' do

    it 'instantiates a repository for the model' do
      SomeModel.extend Restish::RepositoryWrapper
      SomeModel.repository.should be_kind_of(SomeModelRepository)
    end
    
    it 'instantiates different repository for each call' do
      a_id = model_class.repository.object_id
      b_id = model_class.repository.object_id
      a_id.should_not eq b_id
    end
  end

  [:all, :find, :find_locally, :save, :filter, :post].each do |method|
    context ".#{method}" do
      it 'calls a repository' do
        model_class.stub(:repository).and_return(repository)
        repository.should_receive(method).with(opt: '/example')
        model_class.send(method, opt: '/example')
      end
    end
  end

end
