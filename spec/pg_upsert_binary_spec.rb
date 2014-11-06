require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "pg_upsert from file with binary data" do
  before(:each) do
    @conn ||= PG::Connection.open(
      :host     => "localhost",
      :user     => "postgres",
      :password => "postgres",
      :port     => 5432,
      :dbname   => "ar_pg_copy_test"
    )
    @conn.exec_params %{
      TRUNCATE TABLE test_models;
      SELECT setval('test_models_id_seq', 1, false);
    }
  end

  before do
    DateTime.stub(:now).and_return (DateTime.parse("2012-01-01").utc)
  end

  def timestamp
    DateTime.now.utc.to_s
  end

  it "imports from file if path is passed without field_map" do
    TestModel.pg_upsert File.expand_path('spec/fixtures/2_col_binary_data.dat'), :format => :binary, columns: [:id, :data]

    expect(
      TestModel.first.attributes
    ).to include('data' => 'text', 'created_at' => timestamp, 'updated_at' => timestamp)
  end

  it "throws an error when importing binary file without columns list" do
    # Since binary data never has a header row, we'll require explicit columns list
    expect{
      TestModel.pg_upsert File.expand_path('spec/fixtures/2_col_binary_data.dat'), :format => :binary
    }.to raise_error "Either the :columns option or :header => true are required"
  end

end

