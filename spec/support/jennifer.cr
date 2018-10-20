require "jennifer"
require "jennifer/adapter/postgres"

Jennifer::Config.configure do |conf|
  # conf.logger.level = Logger::DEBUG
  conf.logger.level = Logger::INFO
  conf.host = "localhost"
  conf.adapter = "postgres"
  conf.migration_files_path = "./spec/support/migrations"
  conf.db = "form_object_test"
  conf.user = ENV["DB_USER"]? || "developer"
  conf.password = ENV["DB_PASSWORD"]? || "1qazxsw2"
end
