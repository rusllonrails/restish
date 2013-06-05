require 'spec_helper'

describe Restish::Collection do

  describe '#meta_params=' do

    it 'assigns next_url, prev_url and count_all from given meta' do
      collection = Restish::Collection.new
      collection.meta_params = {
        'next_url' => 'next',
        'prev_url' => 'prev',
        'count' => 123
      }
      expect(collection.instance_variable_get(:@next_url)).to eq 'next'
      expect(collection.instance_variable_get(:@prev_url)).to eq 'prev'
      expect(collection.instance_variable_get(:@count_all)).to eq 123
    end

  end

end
