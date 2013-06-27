require 'spec_helper'

class Foobar < Restish::Model; end

class FoobarAdapter < Restish::Adapter; end

module Foo; end

class Foo::Bar < Restish::Model; end

class Foo::BarAdapter < Restish::Adapter; end

describe Restish::Adapter do
  describe '#find' do
    let(:response_body) do
      { "foobar" => { "name" => "Da category" } }
    end
    let(:response) { mock 'Response', body: response_body, status: 200 }
    let(:connection) { mock 'Connection', get: response  }
    let(:foobar_adapter) { FoobarAdapter.new(connection) }

    it 'gets foobars over HTTP' do
      connection.should_receive(:get).with(/foobars\/123/)
      foobar_adapter.find(123)
    end

    context '200 OK response' do
      it 'unpacks attributes from response' do
        Foobar.should_receive(:new).with("name" => "Da category")
        foobar_adapter.find(123)
      end

      it 'returns materialized model' do
        foobar_adapter.find(123).size.should eq 1
        foobar_adapter.find(123).should be_kind_of Foobar
      end
    end
  end

  describe '#all' do
    let(:response_body) do
      { "foobars" => [{ "name" => "Da category" }] }
    end
    let(:response) { mock 'Response', body: response_body, status: 200 }
    let(:connection) { mock 'Connection', get: response  }
    let(:foobar_adapter) { FoobarAdapter.new(connection) }

    it 'gets foobars over HTTP' do
      connection.should_receive(:get).with(/foobars/)
      foobar_adapter.all
    end

    context 'with custom URL specified' do
      it 'gets specified URL over HTTP' do
        connection.should_receive(:get).with('myurl')
        foobar_adapter.all(url: 'myurl')
      end
    end

    context '200 OK response' do
      it 'unpacks attributes from response' do
        Foobar.should_receive(:new).with("name" => "Da category")
        foobar_adapter.all
      end

      it 'returns materialized models' do
        foobar_adapter.all.size.should eq 1
        foobar_adapter.all[0].should be_kind_of Foobar
      end
    end

    context '200 OK empty response' do
      let(:response_body) { {} }

      it 'raises an exception' do
        expect do
          foobar_adapter.all
        end.to raise_error
      end

    end

    context '500 Internal Server Error response' do
      before do
        response.stub(:status).and_return 500
      end

      it 'raises an exception' do
        expect do
          foobar_adapter.all
        end.to raise_error
      end
    end
  end

  describe '#create' do
    let(:json)  { { 'foobar' => { 'name' => 'Da name' } } }
    let(:model) { mock 'Model', to_json: json }
    let(:response) { mock 'Response', body: json, status: 201 }
    let(:connection) { mock 'Connection', post: response  }
    let(:foobar_adapter) { FoobarAdapter.new(connection) }

    it 'posts serialized JSON over HTTP' do
      connection.should_receive(:post).with(/foobars/, json)
      foobar_adapter.create(model)
    end

    context '201 Created response' do
      it 'unpacks attributes from response' do
        Foobar.should_receive(:new).with('name' => 'Da name')
        foobar_adapter.create(model)
      end

      it 'returns materialized model' do
        foobar_adapter.create(model).size.should eq 1
        foobar_adapter.create(model).should be_kind_of Foobar
      end
    end

    context '422 Unprocessable Entity response' do
      let(:response) { mock 'Response', body: json, status: 422 }
      it 'raises an exception' do
        expect { foobar_adapter.create(model) }.to raise_error(Restish::Adapter::UnprocessableEntityError)
      end
    end
  end

  describe '#update' do
    let(:json)  { { 'foobar' => { 'name' => 'Da name', 'id' => 3 } } }
    let(:update_json)  { { 'foobar' => { 'name' => 'John Doe', 'id' => 3 } } }
    let(:model) { mock 'Model', json['foobar'].merge(to_json: json) }
    let(:response) { mock 'Response', body: update_json, status: 200 }
    let(:connection) { mock 'Connection', put: response  }
    let(:foobar_adapter) { FoobarAdapter.new(connection) }

    it 'posts serialized JSON over HTTP' do
      connection.should_receive(:put).with(/foobars\/3/, update_json)
      foobar_adapter.update(model, update_json)
    end

    context '201 Created response' do
      it 'unpacks attributes from response' do
        Foobar.should_receive(:new).with('name' => 'John Doe', 'id' => 3)
        foobar_adapter.update(model, update_json)
      end

      it 'returns updated model' do
        updated_model = foobar_adapter.update(model, update_json)
        updated_model.size.should eq 2
        updated_model.should be_kind_of Foobar
        updated_model.should_not eq model
      end
    end

    context '422 Unprocessable Entity response' do
      let(:response) { mock 'Response', body: update_json, status: 422 }
      it 'raises an exception' do
        expect { foobar_adapter.update(model, update_json) }.to raise_error(Restish::Adapter::UnprocessableEntityError)
      end
    end

    context '404 Not Found response' do
      let(:response) { mock 'Response', status: 404 }
      it 'raises an exception' do
        expect { foobar_adapter.update(model, update_json) }.to raise_error(Restish::Adapter::NotFoundError)
      end
    end

  end


  describe '#url_for' do
    context 'with :all argument' do
      it 'constructs resource URL' do
        adapter = FoobarAdapter.new(nil)
        adapter.url_for(:all).should eq 'foobars'
      end
    end

    context 'with ID as argument' do
      it 'constructs resource URL' do
        adapter = FoobarAdapter.new(nil)
        adapter.url_for(123).should eq 'foobars/123'
      end
    end

    context 'for model with module prefix' do
      it 'constructs url with slash (/) as modul/class separator in it' do
        adapter = Foo::BarAdapter.new(nil)
        adapter.url_for(123).should eq 'foo/bars/123'
      end
    end
  end

  context '#handle_response' do
    let (:connection) { mock 'Connection' }
    let (:adapter) { Foo::BarAdapter.new(connection) }

    it 'raises UnauthorizedError on 401 Unauthorized' do
      connection.stub(:post).and_return(mock('Response', status: 401))
      expect do
        adapter.create(Foobar.new)
      end.to raise_error(Restish::Adapter::UnauthorizedError)
    end
  end
end
