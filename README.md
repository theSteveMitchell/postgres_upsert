# postgres_upsert [![Build Status](https://travis-ci.org/theSteveMitchell/postgres_upsert.svg?branch=master)](https://travis-ci.org/theSteveMitchell/postgres_upsert)

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

```ruby
PostgresUpsert.write <class_or_table_name>, <io_object_or_file_path>[, options]
```
<class_or_table_name> is either an ActiveRecord::Base subclass, or a string representing the name of a database table.
<io_object_or_file_path> can be either a string representing a file path, or an io object (StringIO, FileIO, etc.)

options:
- :delimiter - the string to use to delimit fields from the source data.  Default is ","
- :header => specifies if the file/io source contains a header row.  Either :header option must be true, or :columns list must be passed.  Default true
- :key_column => the primary key or unique key column on your destination table, used to distinguish new records from existing records.  Default is the primary_key of your destination table/model.
- :update_only => when true, postgres_upsert will ONLY update existing records, and not insert new.  Default is false.

## Examples
for these examples let's assume we have a users table and model:
```ruby
class User < ActiveRecord::Base
```
In the rails console we can run:
```ruby
PostgresUpsert.write User, "/tmp/users.csv"
```

This command will use the headers in the CSV file as fields of the target table (by default)
If the CSV file's header does not match the field names of the User class, you can pass a map in the options parameter.
```ruby
PostgresUpsert.write "users", "/tmp/users.csv", :map => {'name' => 'first_name'}
```
The `name` column in the CSV file will be mapped to the `first_name` field in the users table.

postgres_upsert  supports 'merge' operations, which is not yet natively supported in Postgres.  The data can include both new and existing records, and postgres_upsert will handle either update or insert of records appropriately.  Since the Postgres COPY command does not handle this, postgres_upsert accomplishes it using an intermediary temp table.

The merge/upsert happens in 5 steps (assume your data table is called "users")
* create a temp table named users_temp_123 where "123" is a random int.  In postgres temp tables are only visible to the current database session, so naming conflicts should not be a problem.  We add this random suffix just for additional safety.
* COPY the data to user_temp
* issue a query to insert all new records from users_temp_123 into users ("new" records are those records whos primary key does not already exist in the users)
* issue a query to update all existing records in users with the data in users_temp_123 ("existing" records are those whose primary key already exists in the users table)
* drop the temp table.

## timestamp columns

currently postgres_upsert detects and manages the default rails timestamp columns `created_at` and `updated_at`.  If these fields exist in your destination table, postgres_upsert will keep these current as expected.  I recommend you do NOT include these fields in your source CSV/IO, as postgres_upsert will not honor them.

* newly inserted records get a current timestamp for created_at
* records existing in the source file/IO will get an update to their updated_at timestamp (even if all fields maintain the same value)
* records that are in the destination table but not the source will not have their timestamps changed.


### overriding the key_column

By default postgres_upsert uses the primary key on your ActiveRecord table to determine if each record should be inserted or updated.  You can override the column using the :key_field option:

```ruby
PostgresUpsert.write User "/tmp/users.csv", :key_column => ["external_twitter_id"]
```

obviously, the field you pass must be a unique key in your database (this is not enforced at the moment, but will be)

passing :update_only => true will ensure that no new records are created, but records will be updated.

### Insert/Update Counts
PostgresUpsert with also return a PostgresUpsert::Result object that will tell you how many records were inserted or updated:

```ruby
User.delete_all
result = PostgresUpsert.write User "/tmp/users.csv"
result.inserted 
# => 10000
result.updated
# => 0
```

### Benchmarks!

Given a User model, (validates presence of email and paassword)
```console
2.1.3 :008 > User
 => User(id: integer, email: string, password: string, created_at: datetime, updated_at: datetime) 
```

And the following railsy code to create 10,000 users:
```ruby
def insert_dumb
    time = Benchmark.measure do
      (1..10000).each do |n|
        User.create!(:email => "number#{n}@postgres.up", :password => "#{(n-5..n).to_a.join('')}")
      end
    end
  puts time
end
```

Compared to the following code using Postgres_upsert:
```ruby
def insert_smart
    time = Benchmark.measure do
      csv_string = CSV.generate do |csv|
        csv << %w(email password)
        (1..10000).each do |n|
          csv << ["number#{n}@postgres.up", "#{(n-5..n).to_a.join('')}"]
        end
      end
      io = StringIO.new(csv_string)
      PostgresUpsert.write User io, key_column: "email"
    end
    puts time
end
```

let's compare!

```console
2.1.3 :002 > insert_dumb
   #...snip  ~30k lines of output :( (10k queries, each wrapped in a transaction)
   (0.3ms)  COMMIT
26.639246
2.1.3 :004 > User.delete_all
  SQL (15.4ms)  DELETE FROM "users"
2.1.3 :006 > insert_smart
   #...snip ~30 lines of output, composing 5 sql queries...
0.275503
```

...That's 26.6 seconds for classic create loop... vs. 0.276 seconds for postgres_upsert.  
This is over 96X faster.  And it only cost me ~6 extra lines of code.

Note that for the benchmark, my database is local.  The performance improvement should only increase when we have network latency to worry about.

## Note on Patches/Pull Requests

* Fork the project
* add your feature/fix to your fork(rpsec tests pleaze)
* submit a PR
* If you find an issue but can't fix in in a PR, please log an issue.  I'll do my best.

