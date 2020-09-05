#!/usr/bin/env -S ruby -W0

$:.unshift("#{__dir__}/lib")

require "hackers"
require "sandbox"

Dir.chdir(__dir__)
CONFIGS_DIR = "configs"
DEFAULT_CONFIG = "default"

configFile = "#{DEFAULT_CONFIG}.conf"
configFile = "#{ARGV[1]}.conf" if ARGV[0] == "-c"
unless File.file?("#{CONFIGS_DIR}/#{configFile}")
  puts "#{$0}: Can't load config #{ARGV[1]}"
  exit
end
config = File.read("#{CONFIGS_DIR}/#{configFile}")
begin
  config = JSON.parse(config)
rescue JSON::ParserError => e
  puts "#{$0}: Invalid config format"
  puts
  puts e
  exit
end

game = Trickster::Hackers::Game.new(config)
shell = Sandbox::Shell.new(game)
unless config["autocmd"].nil?
  config["autocmd"].each do |cmd|
    shell.exec(cmd)
  end
end
shell.readline
