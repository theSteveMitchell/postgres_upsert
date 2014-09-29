require 'rubygems'
require 'active_record'
require 'postgres_upsert/active_record'
require 'rails'

class PostgresCopy < Rails::Railtie

  initializer 'postgres_upsert' do
    ActiveSupport.on_load :active_record do
      require "postgres_upsert/active_record"
    end
  end
end
