# postgres_upsert

Allows your  rails app to load data in a very fast way, avoiding calls to ActiveRecord.

Using the PG gem and postgres's powerful COPY command, you can create thousands of rails objects in your db in a single query.

## Compatibility Note
The master branch requires the 'pg' gem which only supports MRI ruby.  the jruby branch requires 'activerecord-jdbcpostgresql-adapter' which, of course only supports JRuby.  Installation is the same whatever your platform.

## Install

Put it in your Gemfile

    gem 'postgres_upsert'

Run the bundle command

    bundle

## Usage

The gem will add the additional class method to ActiveRecord::Base

* pg_upsert io_object_or_file_path, [options]

io_object_or_file_path => is a file path or an io object (StringIO, FileIO, etc.)

options:
:delimiter - the string to use to delimit fields.  Default is ","
:format - the format of the file (valid formats are :csv or :binary).  Default is :csv
:header => specifies if the file/io source contains a header row.  Either :header option must be true, or :columns list must be passed.  Default true
:key_column => the primary key or unique key column on your ActiveRecord table, used to distinguish new records from existing records.  Default is the primary_key of your ActiveRecord model class.
:update_only => when true, postgres_upsert will ONLY update existing records, and not insert new.  Default is false.

pg_upsert will allow you to copy data from an arbritary IO object or from a file in the database server (when you pass the path as string).
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

To copy a binary formatted data file or IO object you can specify the format as binary

```ruby
User.pg_upsert "/tmp/users.dat", :format => :binary, :columns => ["id, "name"]
```

Which will generate the following SQL command:

```sql
COPY users (id, name) FROM '/tmp/users.dat' WITH BINARY
```

NOTE: binary files do not include header columns, so passing a :columns array is required for binary files.


pg_upsert  supports 'upsert' or 'merge' operations.  In other words, the data source can contain both new and existing objects, and pg_upsert will handle either case.  Since the Postgres native COPY command does not handle updating existing records, pg_upsert accomplishes update and insert using an intermediary temp table:

This merge/upsert happend in 5 steps (assume your data table is called "users")
* create a temp table named users_temp_123 where "123" is a randomly generated number.  In postgres temp tables are only visible to the current database session, so naming conflicts should not be a problem.  We add this random suffix just for fun.
* COPY the data to user_temp
* issue a query to insert all new records from users_temp_123 into users ("new" records are those records whos primary key does not already exist in the users)
* issue a query to update all existing records in users with the data in users_temp_123 ("existing" records are those whose primary key already exists in the users table)
* drop the temp table.

### timestamp columns

currently pg_upsert detects and manages the default rails timestamp columns created_at and updated_at.  If these fields exist in your destination table, pg_upsert will keep these current as expected.  I recommend you do NOT include these fields in your source CSV/IO, as pg_upsert will not honor them.

* newly inserted records get a current timestamp for created_at
* records existing in the source file/IO will get an update to their updated_at timestamp (even if all fields maintain the same value)
* records that are in the destination table but not the source will not have their timestamps changed.


### overriding the key_column

By default pg_upsert uses the primary key on your ActiveRecord table to determine if each record should be inserted or updated.  You can override the column using the :key_field option:

```ruby
User.pg_upsert "/tmp/users.dat", :format => :binary, :key_column => ["external_twitter_id"]
```

obviously, the field you pass must be a unique key in your database (this is not enforced at the moment, but will be)

passing :update_only = true will ensure that no new records are created, but records will be updated.

## Note on Patches/Pull Requests

* Fork the project
* add your feature/fix to your fork(rpsec tests pleaze)
* submit a PR
* If you find an issue but can't fix in in a PR, please log an issue.  I'll do my best.

