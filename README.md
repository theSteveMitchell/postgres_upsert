postgres_upsert
=========================

A rubygem that integrates with ActiveRecord to insert/update large data sets into the database efficiently. Data can be in the form of a ruby hash, or IO serving CSV-formatted source (e.g. StringIO or FileIO)

Caveats
==========
Obviously the performance boost comes from using the postgres's COPY command, which is very fast for large amounts of data.  There is no ActiveRecord update, so you don't get callbacks, validations, or timestamp updates.  Be warned.

How we Do
=========
Postgres does not yet support the 'merge' operation natively (a.k.a upsert or insert-or-update).  We workaround this using a temp table in postgres.  For each update operation we 

1- create a temp table, 
2- populate it using COPY, 
3- instert all records from temp table into the destination table, where the Primary key does not exist in the destinatino table
4 - update records in the destination table with data in temp table, where the primary key already exists
5 - drop temp table.

Postgres's temp tables are luckily visible only on the current session (not just to the current user) so there should be no chance of collision with other tables.  We could get away with just truncating the temp table, instead of dropping, but it doesn't seem to make a difference from a user perspective.  

Benchmark
=========
In a new Rails app with a model User(:email, :username, :name) and only presence and uniqueness validations on those fields:

```ruby
Benchmark.realtime do 
  1_000_000.times do |i|
    User.create(email
  end
end
#SNIP
=> 2710.734565 #45 minutes, 10 seconds

User.delete_all
Benchmark.realtime do 
  new_users = []
  1_000_000.times do
    new_users << {}
  end
  
  User.postgres_upsert new_users, :through_table => 'users_temp' 
end
=> 45
```


