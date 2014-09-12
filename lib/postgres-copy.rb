require 'rubygems'
require 'active_record'
require 'postgres-copy/active_record'
require 'rails'

class PostgresCopy < Rails::Railtie

  initializer 'postgres-copy' do
    ActiveSupport.on_load :active_record do
      require "postgres-copy/active_record"
    end
  end
end
