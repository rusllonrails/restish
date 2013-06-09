require 'spec_helper'

class TheCopenhagenModel < Restish::Model
end

describe Restish::Errors do

  context '#from_hash' do
    let(:model) { TheCopenhagenModel.new(owner: 'Schrödinger', name: 'cat', alive: true) }
    let(:errors) { { 'alive' => ['is invalid'], 'cyanide_flask' => ["can't be empty"] } }

    before do
      model.errors.from_hash(errors)
    end

    it 'populates errors for an existing attribute' do
      model.errors['alive'].should include('is invalid')
    end

    it 'adds unattributed errors to base' do
      model.errors['cyanide_flask'].should be_blank
      model.errors[:base].should include("Cyanide flask can't be empty")
    end

    it 'saves unique errors for base' do
      model.errors[:base].should include("Cyanide flask can't be empty")
      model.errors.from_hash(errors)
      model.errors[:alive].should have(1).item
      model.errors[:base].should have(1).item
    end

  end

end
