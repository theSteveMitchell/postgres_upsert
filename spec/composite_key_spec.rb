require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "pg_upsert from file with CSV format" do

  before do
    DateTime.stub_chain(:now, :utc).and_return (DateTime.parse("2012-01-01").utc)
  end

  def timestamp
    DateTime.now.utc
  end

  context 'composite_key_support' do
    it 'inserts records if the passed match composite key doesnt exist' do
      file = File.open(File.expand_path('spec/fixtures/composite_key_with_header.csv'), 'r')

      PostgresUpsert.write(CompositeKeyModel, file, :unique_key => ["comp_key_1", "comp_key_2"])
      expect(
        CompositeKeyModel.last.attributes
      ).to include("data" => "test data 2")
    end

    it 'updates records if the passed composite key exists' do
      file = File.open(File.expand_path('spec/fixtures/composite_key_with_header.csv'), 'r')
      existing = CompositeKeyModel.create(comp_key_1: 2, comp_key_2:3, data: "old stuff")

      PostgresUpsert.write(CompositeKeyModel, file, :unique_key => ["comp_key_1", "comp_key_2"])

      expect(
        CompositeKeyModel.find_by({comp_key_1: 2, comp_key_2:3}).attributes
      ).to include("data" => "test data 2")

      expect(
        CompositeKeyModel.find_by({comp_key_1: 1, comp_key_2:2}).attributes
      ).to include("data" => "test data 1")
    end

    it 'fails if composite keys are not unique.' do
      file = File.open(File.expand_path('spec/fixtures/composite_nonkey_with_header.csv'), 'r')
      existing = CompositeKeyModel.create(comp_key_1: 1, comp_key_2:2, data: "old stuff")

       expect{
        PostgresUpsert.write(CompositeKeyModel, file, :unique_key => ["comp_key_1", "comp_key_2"])
      }.to raise_error(/Check to make sure your key is unique/)
    end
    
  end


end
