# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(__dir__, 'lib'))

require 'cli/sandbox'
require 'hackers'

CONFIGS_DIR     = 'configs'
DEFAULT_CONFIG  = 'default.conf'
SANDBOX_FILE    = 'bin/sandbox'

Dir.chdir(__dir__)

desc 'Run sandbox'
task :run, [:config] do |_task, args|
  unless args[:config]
    puts 'Specify config name'
    exit
  end

  file = "#{CONFIGS_DIR}/#{args[:config]}.conf"
  unless File.exist?(file)
    puts "Config #{args[:config]} doesn't exist"
    exit
  end

  exec("./#{SANDBOX_FILE} -c #{args[:config]}")
end

desc 'News list'
task :news do
  config = Sandbox::Config.new("#{CONFIGS_DIR}/#{DEFAULT_CONFIG}")
  config.load
  game = Trickster::Hackers::Game.new(config)
  news = game.cmdNewsGetList
  news.each do |_, v|
    puts "\e[34m#{v['date']} \e[33m#{v['title']}\e[0m"
    puts "\e[35m#{v['body']}\e[0m"
    puts
  end
end

namespace :account do
  desc 'Create new account'
  task :new, [:name] do |_task, args|
    unless args[:name]
      puts 'Specify config name'
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
    config['id'] = account['id']
    config['password'] = account['password']
    config.save
    puts "New account #{args[:name]} has been created (#{account['id']})"
  end

  desc 'Delete config'
  task :del, [:name] do |_task, args|
    unless args[:name]
      puts 'Specify config name'
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

  desc 'List configs'
  task :list do
    files = Dir.entries(CONFIGS_DIR)
    files.sort!
    files.each do |file|
      next if file =~ /^..?$/

      name = file.split('.').first
      puts name
    end
  end

  desc 'Show config'
  task :show, [:name] do |_task, args|
    unless args[:name]
      puts 'Specify config name'
      exit
    end

    file = "#{CONFIGS_DIR}/#{args[:name]}.conf"
    unless File.exist?(file)
      puts "Config #{args[:name]} doesn't exist"
      exit
    end

    begin
      config = JSON.parse(File.read(file))
    rescue JSON::ParserError => e
      puts "Config #{args[:name]} has invalid format"
      puts
      puts e
      exit
    end

    puts "Configuration #{args[:name]}:"
    config.each do |k, v|
      puts format(
        ' %<key>-20s .. %<value>s',
        key: k,
        value: v
      )
    end
  end
end
