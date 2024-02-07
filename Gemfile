# frozen_string_literal: true

source "https://rubygems.org"

group :test do
    gem "rspec"
    gem "coderay"
    gem "rack-test"
    end
group :test, :development, :production do
    gem "sinatra"
    gem "rack"
    gem "rackup"
    gem "pg"
    gem "sequel"
    gem 'sequel_pg', '>= 1.8', require: 'sequel'
end
group :production do
    gem 'thin'
end
