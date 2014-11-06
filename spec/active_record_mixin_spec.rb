require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class TestModel < ActiveRecord::Base; end

describe "active record extension" do
  before do
    ActiveRecord::Base.establish_connection(
      :adapter  => "postgresql",
      :host     => "localhost",
      :username => "postgres",
      :password => "postgres",
      :port     => 5432,
      :database => "ar_pg_copy_test"
    )
  end

  it "should call writer with correct set of arguments" do
    dbl = double
    PostgresUpsert::Writer.should_receive(:new)
      .with(ActiveRecord::Base.connection.raw_connection, 'test_models', 'path/to/file.csv', {})
      .and_return(dbl)

    dbl.should_receive(:write)

    TestModel.pg_upsert 'path/to/file.csv'
  end
end
