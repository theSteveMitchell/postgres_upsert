require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "pg_upsert from file with binary data" do

  before do
    TestModel.delete_all
    DateTime.stub_chain(:now, :utc).and_return (DateTime.parse("2012-01-01").utc)
  end

  def timestamp
    DateTime.now.utc
  end

  it "imports from file if path is passed without field_map" do
    PostgresUpsert.write TestModel, File.expand_path('spec/fixtures/2_col_binary_data.dat'), :format => :binary, columns: [:id, :data]

    expect(
      TestModel.first.attributes
    ).to include('data' => 'text', 'created_at' => timestamp, 'updated_at' => timestamp)
  end

  it "throws an error when importing binary file without columns list" do
    # Since binary data never has a header row, we'll require explicit columns list
    expect{
      PostgresUpsert.write TestModel, File.expand_path('spec/fixtures/2_col_binary_data.dat'), :format => :binary
    }.to raise_error "Either the :columns option or :header => true are required"
  end

end

