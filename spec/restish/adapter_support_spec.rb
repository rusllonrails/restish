require 'spec_helper'

class TestAdapter
  attr_accessor :conn

  def initialize(conn)
    @conn = conn
  end
end

class TestController
  include Restish::AdapterSupport
end

class TestController2
  include Restish::AdapterSupport
end

describe Restish::AdapterSupport do
  let(:controller) { TestController.new }
  let(:controller_2) { TestController2.new }
  let(:connection) { mock 'Connection' }

  before do
    Restish.adapters = {}
  end

  describe '#adapter' do
    context 'given valid adapter name' do
      it 'returns initialized adapter object instance' do
        Faraday.stub(:new).and_return connection
        adapter = controller.adapter(:test)
        adapter.should be_kind_of(TestAdapter)
        adapter.conn.should eq connection
      end

      it 'it uses adapter-specific connection' do
        TestAdapter.stub(:connection).and_return connection
        adapter = controller.adapter(:test)
        adapter.should be_kind_of(TestAdapter)
        adapter.conn.should eq connection
      end

      # it 'memoizes adapter between controllers' do
      #   Faraday.stub(:new).and_return connection
      #   adapter1 = controller.adapter(:test)
      #   adapter2 = controller_2.adapter(:test)
      #   adapter1.should eq adapter2
      # end
    end

    context 'given nonexistent adapter name' do
      it 'returns initialized adapter object instance' do
        adapter = controller.adapter(:nonexistent)
        adapter.should be_nil
      end
    end
  end
end
