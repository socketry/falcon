# frozen_string_literal: true

# config.ru
require "sequel"

# Turn on single threaded mode
Sequel.single_threaded = true
DB = Sequel.sqlite("data.sqlite3")

run(proc{|env| [200, {}, [DB[:user].get(:name)]]})