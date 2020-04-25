require "jennifer"
require "jennifer/adapter/postgres"

Jennifer::Config.read(File.join(__DIR__, "database.yml"), "test")

Jennifer::Config.configure do |conf|
  # conf.logger.level = Logger::DEBUG
  # conf.logger.level = Logger::INFO
  conf.user = ENV["DB_USER"] if ENV["DB_USER"]?
  conf.password = ENV["DB_PASSWORD"] if ENV["DB_PASSWORD"]?
end
