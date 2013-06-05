require 'spec_helper'
require 'rack/test'

describe Restish::Middleware do
  include Rack::Test::Methods

  def end_app
    lambda { |env| [200, {}, "Coolness"] }
  end

  def app
    Restish::Middleware::IdentityMap.new(end_app)
  end

  before do
    Restish::Repository.stub(:clear_cache)
    Restish.stub(:clear_adapters)
  end

  it 'calls clear_cache on Restish::Repository' do
    Restish::Repository.should_receive(:clear_cache)
    get '/'
  end

  it 'calls clear_adapters on Restis' do
    Restish.should_receive(:clear_adapters)
    get '/'
  end
end
