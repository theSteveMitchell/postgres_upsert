# postgres_upsert

Allows your  rails app to load data in a very fast way, avoiding calls to ActiveRecord.

Using the PG gem and postgres's powerful COPY command, you can create thousands of rails objects in your db in a single query.


## Install

Put it in your Gemfile

    gem 'postgres_upsert'

Run the bundle command

    bundle

## Usage

The gem will add the aditiontal class method to ActiveRecord::Base:

* pg_upsert

### Using pg_upsert

If you want to upsert data into the database, you can use the pg_copy_from method.
It will allow you to copy data from an arbritary IO object or from a file in the database server (when you pass the path as string).
Let's first copy from a file in the database server, assuming again that we have a users table and
that we are in the Rails console:

```ruby
User.pg_upsert "/tmp/users.csv"
```

This command will use the headers in the CSV file as fields of the target table, so beware to always have a header in the files you want to import.
If the column names in the CSV header do not match the field names of the target table, you can pass a map in the options parameter.

```ruby
User.pg_upsert "/tmp/users.csv", :map => {'name' => 'first_name'}
```

In the above example the header name in the CSV file will be mapped to the field called first_name in the users table.
You can also manipulate and modify the values of the file being imported before they enter into the database using a block:

```ruby
User.pg_upsert "/tmp/users.csv" do |row|
  row[0] = "fixed string"
end
```

The above example will always change the value of the first column to "fixed string" before storing it into the database.
For each iteration of the block row receives an array with the same order as the columns in the CSV file.


To copy a binary formatted data file or IO object you can specify the format as binary

```ruby
User.pg_upsert "/tmp/users.dat", :format => :binary
```

NOTE: Columns must line up with the table unless you specify how they map to table columns.

To specify how the columns will map to the table you can specify the :columns option

```ruby
User.pg_copy_from "/tmp/users.dat", :format => :binary, :columns => [:id, :name]
```

Which will generate the following SQL command:

```sql
COPY users (id, name) FROM '/tmp/users.dat' WITH BINARY
```

pg_upsert  supports 'upserting' data using the :through_table option.  Since the Postgres COPY command does not handle updating existing records, pg_upsert accomplishes update and insert using an intermediary temp table:

```ruby
User.pg_upsert "/tmp/users.csv", :through_table => "users_temp"
```

This command will process the data in 5 steps:
* create a temp table called "users_temp".  In postgres temp tables are only visible to the current database session, so naming conflicts should not be a problem.
* COPY the data to user_temp
* issue a query to insert all new records from users_temp into users (newness is dtermined by the presence of the primary key in the users table)
* issue a query to update all records in users with the data in users_temp (matching on primary key)
* drop the temp table.

## Note on Patches/Pull Requests

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2011 Diogo Biazus. See LICENSE for details.
