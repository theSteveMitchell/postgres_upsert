postgres_copy_with_upsert
=========================

Uses Postgres's powerful COPY command to upload large sets of data without individual ActiveRecord updates.  Supports CSV data format or in-memory Hash.  Also supports upsert functionality using a temp table with insert/update.  This method is crazy fast.  
