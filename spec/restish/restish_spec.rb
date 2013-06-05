require 'spec_helper'

describe Restish do
  describe '.clear_adapters' do
    it 'resets adapters to empty hash' do
      Restish.adapters = { 'yeehaw' => mock }
      Restish.clear_adapters
      Restish.adapters.should eq({})
    end
  end
end
