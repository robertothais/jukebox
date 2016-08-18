require 'bundler'
require 'dotenv'
ROOT_DIR = File.dirname(__FILE__)
Dotenv.load(File.join(ROOT_DIR, '.env'))
Bundler.require
require 'rainbow/ext/string'
ENV['DATABASE_URL'] = "sqlite3://#{File.join(ROOT_DIR, ENV['DATABASE_PATH'])}"
ActiveRecord::Base.establish_connection
require_all File.join(ROOT_DIR, 'lib')
Hirb.enable pager: false