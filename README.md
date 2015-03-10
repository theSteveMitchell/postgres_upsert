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

The gem will add the additional class method to ActiveRecord::Base

* pg_upsert io_object_or_file_path, [options]

io_object_or_file_path => is a file path or an io object (StringIO, FileIO, etc.)

options:
- :delimiter - the string to use to delimit fields.  Default is ","
- :header => specifies if the file/io source contains a header row.  Either :header option must be true, or :columns list must be passed.  Default true
- :key_column => the primary key or unique key column on your ActiveRecord table, used to distinguish new records from existing records.  Default is the primary_key of your ActiveRecord model class.
- :update_only => when true, postgres_upsert will ONLY update existing records, and not insert new.  Default is false.

## Examples

Let's first copy from a file on the database server, assuming that we have a users table and
that we are in the Rails console:

```ruby
User.pg_upsert "/tmp/users.csv"
```

This command will use the headers in the CSV file as fields of the target table, so beware to always have a header in the files you want to import.
If the column names in the CSV header do not match the field names of the target table, you can pass a map in the options parameter.
```ruby
User.pg_upsert "/tmp/users.csv", :map => {'name' => 'first_name'}
```
The header name in the CSV file will be mapped to the field called first_name in the users table.


pg_upsert  supports the 'merge' operation, which is not yet natively supported in Postgres.  The data can include both new and existing records, and pg_upsert will handle either update or insert of each record appropriately.  Since the Postgres COPY command does not handle this, pg_upsert accomplishes it using an intermediary temp table:

The merge/upsert happens in 5 steps (assume your data table is called "users")
* create a temp table named users_temp_123 where "123" is a randomly generated number.  In postgres temp tables are only visible to the current database session, so naming conflicts should not be a problem.  We add this random suffix just for fun.
* COPY the data to user_temp
* issue a query to insert all new records from users_temp_123 into users ("new" records are those records whos primary key does not already exist in the users)
* issue a query to update all existing records in users with the data in users_temp_123 ("existing" records are those whose primary key already exists in the users table)
* drop the temp table.

## timestamp columns

currently pg_upsert detects and manages the default rails timestamp columns `created_at` and `updated_at`.  If these fields exist in your destination table, pg_upsert will keep these current as expected.  I recommend you do NOT include these fields in your source CSV/IO, as pg_upsert will not honor them.

* newly inserted records get a current timestamp for created_at
* records existing in the source file/IO will get an update to their updated_at timestamp (even if all fields maintain the same value)
* records that are in the destination table but not the source will not have their timestamps changed.


### overriding the key_column

By default pg_upsert uses the primary key on your ActiveRecord table to determine if each record should be inserted or updated.  You can override the column using the :key_field option:

```ruby
User.pg_upsert "/tmp/users.csv", :key_column => ["external_twitter_id"]
```

obviously, the field you pass must be a unique key in your database (this is not enforced at the moment, but will be)

passing :update_only = true will ensure that no new records are created, but records will be updated.

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
      User.pg_upsert io, key_column: "email"
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

