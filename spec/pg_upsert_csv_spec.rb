require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "pg_upsert from file with CSV format" do
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
      TRUNCATE TABLE three_columns;
      SELECT setval('test_models_id_seq', 1, false);
    }
  end

  before do
    PostgresUpsert::Writer.any_instance.stub(:now).and_return Time.parse("2012-01-01").utc
  end

  def timestamp
    Time.parse("2012-01-01").utc
  end

  def sample_record(table_name = 'test_models', id = 1)
    pg_result = @conn.exec_params "SELECT * FROM #{table_name} WHERE id = #{id};"
    pg_result.map{ |row| row }.first.tap do |fields|
      return if fields.nil?
      fields['id'] = fields['id'].to_i
      fields['created_at'] = Time.parse(fields['created_at']).utc if fields['created_at']
      fields['updated_at'] = Time.parse(fields['updated_at']).utc if fields['updated_at']
    end
  end

  it "should import from file if path is passed without field_map" do
    PostgresUpsert::Writer.new(@conn, 'test_models', File.expand_path('spec/fixtures/comma_with_header.csv')).write
    expect(
      sample_record
    ).to include('data' => 'test data 1', 'created_at' => timestamp, 'updated_at' => timestamp)
  end

  it "correctly handles delimiters in content" do
    PostgresUpsert::Writer.new(@conn, 'test_models', File.expand_path('spec/fixtures/comma_with_header_and_comma_values.csv')).write
    expect(
      sample_record
    ).to include('data' => 'test, the data 1', 'created_at' => timestamp, 'updated_at' => timestamp)
  end

  it "throws error if csv is malformed" do
    expect{
      PostgresUpsert::Writer.new(@conn, 'test_models', File.expand_path('spec/fixtures/comma_with_header_and_unquoted_comma.csv')).write
    }.to raise_error
  end

  it "throws error if the csv has mixed delimiters" do
    expect{
      PostgresUpsert::Writer.new(@conn, 'test_models', File.expand_path('spec/fixtures/tab_with_error.csv'), :delimiter => "\t").write
    }.to raise_error
  end

  it "should import from IO without field_map" do
    PostgresUpsert::Writer.new(@conn, 'test_models', File.open(File.expand_path('spec/fixtures/comma_with_header.csv'), 'r')).write
    expect(
      sample_record
    ).to include('data' => 'test data 1', 'created_at' => timestamp, 'updated_at' => timestamp)
  end

  it "should import with custom delimiter from path" do
    PostgresUpsert::Writer.new(@conn, 'test_models', File.expand_path('spec/fixtures/semicolon_with_header.csv'), :delimiter => ';').write
    expect(
      sample_record
    ).to include('data' => 'test data 1', 'created_at' => timestamp, 'updated_at' => timestamp)
  end

  it "should import with custom delimiter from IO" do
    PostgresUpsert::Writer.new(@conn, 'test_models', File.open(File.expand_path('spec/fixtures/semicolon_with_header.csv'), 'r'), :delimiter => ';').write
    expect(
      sample_record
    ).to include('data' => 'test data 1', 'created_at' => timestamp, 'updated_at' => timestamp)
  end

  it "should not expect a header when :header is false" do
    PostgresUpsert::Writer.new(@conn, 'test_models', File.open(File.expand_path('spec/fixtures/comma_without_header.csv'), 'r'), :header => false, :columns => [:id,:data]).write
    expect(
      sample_record
    ).to include('data' => 'test data 1', 'created_at' => timestamp, 'updated_at' => timestamp)
  end

  it "should be able to map the header in the file to diferent column names" do
    PostgresUpsert::Writer.new(@conn, 'test_models', File.open(File.expand_path('spec/fixtures/tab_with_different_header.csv'), 'r'), :delimiter => "\t", :map => {'cod' => 'id', 'info' => 'data'}).write

    expect(
      sample_record
    ).to include('data' => 'test data 1', 'created_at' => timestamp, 'updated_at' => timestamp)
  end

  it "should be able to map the header in the file to diferent column names with custom delimiter" do
    PostgresUpsert::Writer.new(@conn, 'test_models', File.open(File.expand_path('spec/fixtures/semicolon_with_different_header.csv'), 'r'), :delimiter => ';', :map => {'cod' => 'id', 'info' => 'data'}).write

    expect(
      sample_record
    ).to include('data' => 'test data 1', 'created_at' => timestamp, 'updated_at' => timestamp)
  end

  it "should ignore empty lines" do
    PostgresUpsert::Writer.new(@conn, 'test_models', File.open(File.expand_path('spec/fixtures/tab_with_extra_line.csv'), 'r'), :delimiter => "\t").write

    expect(
      sample_record
    ).to include('data' => 'test data 1', 'created_at' => timestamp, 'updated_at' => timestamp)
  end

  it "should not create timestamps when the model does not include them" do
    PostgresUpsert::Writer.new(@conn, 'reserved_word_models', File.expand_path('spec/fixtures/reserved_words.csv'), :delimiter => "\t").write

    expect(
      sample_record('reserved_word_models', 1)
    ).to eq("group"=>"group name", "id"=>1, "select"=>"test select")
  end

  context "upserting data to handle inserts and creates" do
    let(:original_created_at) { (Date.today - 5).to_time.utc }

    before(:each) do
      @conn.exec_params "INSERT INTO test_models (id, data, created_at) VALUES(1, 'From the before time, in the long long ago', '#{original_created_at}')"
    end

    it "should not violate primary key constraint" do
      expect{
        PostgresUpsert::Writer.new(@conn, 'test_models', File.expand_path('spec/fixtures/comma_with_header.csv')).write
      }.to_not raise_error
    end

    it "should upsert (update existing records and insert new records)" do
      PostgresUpsert::Writer.new(@conn, 'test_models', File.expand_path('spec/fixtures/tab_with_two_lines.csv'), :delimiter => "\t").write

      expect(
        sample_record
      ).to eq("id"=>1, "data"=>"test data 1", "created_at" => original_created_at, "updated_at" => timestamp)
      expect(
        sample_record('test_models', 2)
      ).to eq("id"=>2, "data"=>"test data 2", "created_at" => timestamp, "updated_at" => timestamp)
    end

    it "should require columns option if no header" do
      expect{
        PostgresUpsert::Writer.new(@conn, 'test_models', File.expand_path('spec/fixtures/2_col_binary_data.dat'), :format => :binary).write
      }.to raise_error("Either the :columns option or :header => true are required")
    end

    it "should clean up the temp table after completion" do
      PostgresUpsert::Writer.new(@conn, 'test_models', File.expand_path('spec/fixtures/tab_with_two_lines.csv'), :delimiter => "\t").write
      pg_result = @conn.exec_params <<-sql
        SELECT table_schema,table_name
        FROM information_schema.tables
        ORDER BY table_schema,table_name;
      sql

      table_names = pg_result.map{ |row| row['table_name'] }
      table_names.should_not include("test_models_temp")
    end

    it "should gracefully drop the temp table if it already exists" do
      @conn.exec_params "CREATE TEMP TABLE test_models_temp (LIKE test_models);"
      PostgresUpsert::Writer.new(@conn, 'test_models', File.expand_path('spec/fixtures/tab_with_two_lines.csv'), :delimiter => "\t").write

      expect(
        sample_record
      ).to eq("id"=>1, "data"=>"test data 1", "created_at" => original_created_at, "updated_at" => timestamp)
      expect(
        sample_record('test_models', 2)
      ).to eq("id"=>2, "data"=>"test data 2", "created_at" => timestamp, "updated_at" => timestamp)
    end

    it "should be able to copy using custom set of columns" do
      @conn.exec_params "INSERT INTO three_columns (id, data, extra, created_at) VALUES(1, 'old stuff', 'neva change!', '#{original_created_at}')"
      PostgresUpsert::Writer.new(@conn, 'three_columns', File.open(File.expand_path('spec/fixtures/tab_only_data.csv'), 'r'), :delimiter => "\t", :columns => ["id", "data"]).write

      expect(
        sample_record('three_columns', 1)
      ).to eq('id' => 1, 'data' => 'test data 1', 'extra' => "neva change!", 'created_at' => original_created_at, 'updated_at' => timestamp)
    end
  end

  context 'overriding the comparison column' do
    it 'updates records based the match column option if its passed in' do
      @conn.exec_params "INSERT INTO three_columns (id, data, extra) VALUES(1, 'old stuff', 'neva change!')"
      file = File.open(File.expand_path('spec/fixtures/no_id.csv'), 'r')

      PostgresUpsert::Writer.new(@conn, 'three_columns', file, :key_column => "data").write
      expect(
        sample_record('three_columns', 1)['extra']
      ).to eq("ABC: Always Be Changing.")
    end

    it 'inserts records if the passed match column doesnt exist' do
      file = File.open(File.expand_path('spec/fixtures/no_id.csv'), 'r')

      PostgresUpsert::Writer.new(@conn, 'three_columns', file, :key_column => "data").write
      expect(
        sample_record('three_columns', 1)
      ).to include("id" => 1, "data" => "old stuff", "extra" => "ABC: Always Be Changing.")
    end
  end

  context 'update only' do
    let(:original_created_at) { (Date.today - 5).to_time.utc }
    before(:each) do
      @conn.exec_params "INSERT INTO test_models (id, data, created_at) VALUES(1, 'From the before time, in the long long ago', '#{original_created_at}')"
    end
    it 'will only update and not insert if insert_only flag is passed.' do
      PostgresUpsert::Writer.new(@conn, 'test_models', File.expand_path('spec/fixtures/tab_with_two_lines.csv'), :delimiter => "\t", :update_only => true).write

      expect(
        sample_record
      ).to eq("id"=>1, "data"=>"test data 1", "created_at" => original_created_at, "updated_at" => timestamp)
      expect(sample_record('test_models', 2)).to be_nil
    end

  end
end

