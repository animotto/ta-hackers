$:.unshift("#{__dir__}/lib")

require "sandbox"
require "hackers"

CONFIGS_DIR     = "configs"
DEFAULT_CONFIG  = "default.conf"

Dir.chdir(__dir__)

desc "News list"
task :news do
  config = Sandbox::Config.new("#{CONFIGS_DIR}/#{DEFAULT_CONFIG}")
  config.load
  game = Trickster::Hackers::Game.new(config)
  news = game.cmdNewsGetList
  news.each do |k, v|
    puts "\e[34m#{v["date"]} \e[33m#{v["title"]}\e[0m"
    puts "\e[35m#{v["body"]}\e[0m"
    puts
  end
end

namespace :account do
  desc "Create new account"
  task :new, [:name] do |task, args|
    unless args[:name]
      puts "Specify config name"
      exit
    end

    file = "#{CONFIGS_DIR}/#{args[:name]}.conf"
    if File.exist?(file)
      puts "Config #{args[:name]} already exists"
      exit
    end

    config = Sandbox::Config.new("#{CONFIGS_DIR}/#{DEFAULT_CONFIG}")
    config.load
    config.file = file
    game = Trickster::Hackers::Game.new(config)
    account = game.cmdPlayerCreate
    config["id"] = account["id"]
    config["password"] = account["password"]
    config.save
    puts "New account #{args[:name]} has been created (#{account["id"]})"
  end

  desc "Delete config"
  task :del, [:name] do |task, args|
    unless args[:name]
      puts "Specify config name"
      exit
    end

    file = "#{CONFIGS_DIR}/#{args[:name]}.conf"
    unless File.exist?(file)
      puts "Config #{args[:name]} doesn't exist"
      exit
    end

    File.delete(file)
    puts "Config #{args[:name]} has been deleted"
  end
end

