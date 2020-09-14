#!/usr/bin/env ruby

$:.unshift("#{__dir__}/lib")

require "optparse"
require "json"

require "hackers"
require "sandbox"

Dir.chdir(__dir__)
CONFIGS_DIR = "configs"
DEFAULT_CONFIG = "default"

options = {
  "config" => DEFAULT_CONFIG,
}
begin
  OptionParser.new do |opts|
    opts.banner = "TricksterArts Hackers sandbox"
    opts.on("-c config", "", "Configuration name") do |v|
      options["config"] = v
    end
  end.parse!
rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
  puts "#{$0}: #{e.message}"
  exit
end

configFile = "#{options["config"]}.conf"
unless File.file?("#{CONFIGS_DIR}/#{configFile}")
  puts "#{$0}: Can't load config #{options["config"]}"
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

