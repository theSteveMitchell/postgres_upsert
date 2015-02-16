require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "pg_upsert from file with binary data" do
  before(:each) do
    conn.exec_params %{
      TRUNCATE TABLE test_models;
      SELECT setval('test_models_id_seq', 1, false);
    }
  end

  before do
    PostgresUpsert::Writer.any_instance.stub(:now).and_return timestamp
  end

  def timestamp
    Time.parse("2012-01-01").utc
  end

  def sample_record
    pg_result = conn.exec_params 'SELECT * FROM test_models LIMIT 1;'
    pg_result.map{ |row| row }.first.tap do |fields|
      fields['id'] = fields['id'].to_i
      fields['created_at'] = Time.parse(fields['created_at']).utc
      fields['updated_at'] = Time.parse(fields['updated_at']).utc
    end
  end

  it "imports from file if path is passed without field_map" do
    PostgresUpsert::Writer.new(conn, 'test_models', File.expand_path('spec/fixtures/2_col_binary_data.dat'),
                               :format => :binary, columns: [:id, :data]).write

    expect(sample_record).to include('data' => 'text', 'created_at' => timestamp, 'updated_at' => timestamp)
  end

  it "throws an error when importing binary file without columns list" do
    # Since binary data never has a header row, we'll require explicit columns list
    expect{
      PostgresUpsert::Writer.new(conn, 'test_models', File.expand_path('spec/fixtures/2_col_binary_data.dat'), :format => :binary).write
    }.to raise_error "Either the :columns option or :header => true are required"
  end

end

