require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "pg_upsert from file with CSV format" do
  before(:each) do
    ActiveRecord::Base.connection.execute %{
      TRUNCATE TABLE test_models;
      TRUNCATE TABLE three_columns;
      SELECT setval('test_models_id_seq', 1, false);
    }
  end

  before do
    DateTime.stub_chain(:now, :utc).and_return (DateTime.parse("2012-01-01").utc)
  end

  def timestamp
    DateTime.now.utc
  end

  it "should import from file if path is passed without field_map" do
    TestModel.pg_upsert File.expand_path('spec/fixtures/comma_with_header.csv')
    expect(
      TestModel.first.attributes
    ).to include('data' => 'test data 1', 'created_at' => timestamp, 'updated_at' => timestamp)
  end

  it "correctly handles delimiters in content" do
    TestModel.pg_upsert File.expand_path('spec/fixtures/comma_with_header_and_comma_values.csv')
    expect(
      TestModel.first.attributes
    ).to include('data' => 'test, the data 1', 'created_at' => timestamp, 'updated_at' => timestamp)
  end

  it "throws error if csv is malformed" do
    expect{
      TestModel.pg_upsert File.expand_path('spec/fixtures/comma_with_header_and_unquoted_comma.csv')
    }.to raise_error
  end

  it "throws error if the csv has mixed delimiters" do
    expect{
      TestModel.pg_upsert File.expand_path('spec/fixtures/tab_with_error.csv'), :delimiter => "\t"
    }.to raise_error
  end

  it "should import from IO without field_map" do
    TestModel.pg_upsert File.open(File.expand_path('spec/fixtures/comma_with_header.csv'), 'r')
    expect(
      TestModel.first.attributes
    ).to include('data' => 'test data 1', 'created_at' => timestamp, 'updated_at' => timestamp)
  end

  it "should import with custom delimiter from path" do
    TestModel.pg_upsert File.expand_path('spec/fixtures/semicolon_with_header.csv'), :delimiter => ';'
    expect(
      TestModel.first.attributes
    ).to include('data' => 'test data 1', 'created_at' => timestamp, 'updated_at' => timestamp)
  end

  it "should import with custom delimiter from IO" do
    TestModel.pg_upsert File.open(File.expand_path('spec/fixtures/semicolon_with_header.csv'), 'r'), :delimiter => ';'
    expect(
      TestModel.first.attributes
    ).to include('data' => 'test data 1', 'created_at' => timestamp, 'updated_at' => timestamp)
  end

  it "should not expect a header when :header is false" do
    TestModel.pg_upsert(File.open(File.expand_path('spec/fixtures/comma_without_header.csv'), 'r'), :header => false, :columns => [:id,:data])

    expect(
      TestModel.first.attributes
    ).to include('data' => 'test data 1', 'created_at' => timestamp, 'updated_at' => timestamp)
  end

  it "should be able to map the header in the file to diferent column names" do
    TestModel.pg_upsert(File.open(File.expand_path('spec/fixtures/tab_with_different_header.csv'), 'r'), :delimiter => "\t", :map => {'cod' => 'id', 'info' => 'data'})

    expect(
      TestModel.first.attributes
    ).to include('data' => 'test data 1', 'created_at' => timestamp, 'updated_at' => timestamp)
  end

  it "should be able to map the header in the file to diferent column names with custom delimiter" do
    TestModel.pg_upsert(File.open(File.expand_path('spec/fixtures/semicolon_with_different_header.csv'), 'r'), :delimiter => ';', :map => {'cod' => 'id', 'info' => 'data'})

    expect(
      TestModel.first.attributes
    ).to include('data' => 'test data 1', 'created_at' => timestamp, 'updated_at' => timestamp)
  end

  it "should ignore empty lines" do
    TestModel.pg_upsert(File.open(File.expand_path('spec/fixtures/tab_with_extra_line.csv'), 'r'), :delimiter => "\t")

    expect(
      TestModel.first.attributes
    ).to include('data' => 'test data 1', 'created_at' => timestamp, 'updated_at' => timestamp)
  end

  it "should not create timestamps when the model does not include them" do
    ReservedWordModel.pg_upsert File.expand_path('spec/fixtures/reserved_words.csv'), :delimiter => "\t"

    expect(
      ReservedWordModel.first.attributes
    ).to eq("group"=>"group name", "id"=>1, "select"=>"test select")
  end

  context "upserting data to handle inserts and creates" do
    let(:original_created_at) {5.days.ago.utc}

    before(:each) do
      TestModel.create(id: 1, data: "From the before time, in the long long ago", :created_at => original_created_at)
    end

    it "should not violate primary key constraint" do
      expect{
        TestModel.pg_upsert File.expand_path('spec/fixtures/comma_with_header.csv')
      }.to_not raise_error
    end

    it "should upsert (update existing records and insert new records)" do
      TestModel.pg_upsert File.expand_path('spec/fixtures/tab_with_two_lines.csv'), :delimiter => "\t"

      expect(
        TestModel.find(1).attributes
      ).to eq("id"=>1, "data"=>"test data 1", "created_at" => original_created_at, "updated_at" => timestamp)
      expect(
        TestModel.find(2).attributes
      ).to eq("id"=>2, "data"=>"test data 2", "created_at" => timestamp, "updated_at" => timestamp)
    end

    it "should require columns option if no header" do
      expect{
        TestModel.pg_upsert File.expand_path('spec/fixtures/2_col_binary_data.dat'), :format => :binary
      }.to raise_error("Either the :columns option or :header => true are required")
    end

    it "should clean up the temp table after completion" do
      TestModel.pg_upsert File.expand_path('spec/fixtures/tab_with_two_lines.csv'), :delimiter => "\t"
      
      ActiveRecord::Base.connection.tables.should_not include("test_models_temp")
    end

    it "should gracefully drop the temp table if it already exists" do
      ActiveRecord::Base.connection.execute "CREATE TEMP TABLE test_models_temp (LIKE test_models);"
      TestModel.pg_upsert File.expand_path('spec/fixtures/tab_with_two_lines.csv'), :delimiter => "\t"

      expect(
        TestModel.find(1).attributes
      ).to eq("id"=>1, "data"=>"test data 1", "created_at" => original_created_at, "updated_at" => timestamp)
      expect(
        TestModel.find(2).attributes
      ).to eq("id"=>2, "data"=>"test data 2", "created_at" => timestamp, "updated_at" => timestamp)
    end

    it "should be able to copy using custom set of columns" do
      ThreeColumn.create(id: 1, data: "old stuff", extra: "neva change!", created_at: original_created_at)
      ThreeColumn.pg_upsert(File.open(File.expand_path('spec/fixtures/tab_only_data.csv'), 'r'), :delimiter => "\t", :columns => ["id", "data"])

      expect(
        ThreeColumn.first.attributes
      ).to eq('id' => 1, 'data' => 'test data 1', 'extra' => "neva change!", 'created_at' => original_created_at, 'updated_at' => timestamp)
    end
  end

  context 'overriding the comparison column' do
    it 'updates records based the match column option if its passed in' do
      three_col = ThreeColumn.create(id: 1, data: "old stuff", extra: "neva change!")
      file = File.open(File.expand_path('spec/fixtures/no_id.csv'), 'r')


      ThreeColumn.pg_upsert(file, :key_column => "data")
      expect(
        three_col.reload.extra
      ).to eq("ABC: Always Be Changing.")
    end

    it 'inserts records if the passed match column doesnt exist' do
      file = File.open(File.expand_path('spec/fixtures/no_id.csv'), 'r')

      ThreeColumn.pg_upsert(file, :key_column => "data")
      expect(
        ThreeColumn.last.attributes
      ).to include("data" => "old stuff", "extra" => "ABC: Always Be Changing.")
    end
  end

  context 'update only' do
    let(:original_created_at) {5.days.ago.utc}
    before(:each) do
      TestModel.create(id: 1, data: "From the before time, in the long long ago", :created_at => original_created_at)
    end
    it 'will only update and not insert if insert_only flag is passed.' do
      TestModel.pg_upsert File.expand_path('spec/fixtures/tab_with_two_lines.csv'), :delimiter => "\t", :update_only => true

      expect(
        TestModel.find(1).attributes
      ).to eq("id"=>1, "data"=>"test data 1", "created_at" => original_created_at  , "updated_at" => timestamp)
      expect{
        TestModel.find(2)
      }.to raise_error(ActiveRecord::RecordNotFound)

    end

  end
end

