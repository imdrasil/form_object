require "sam"
require "../spec/support/jennifer"
require "../spec/support/migrations/*"

load_dependencies "jennifer"

Jennifer::Config.configure do |conf|
  # conf.logger.level = Logger::INFO
end

Sam.help
