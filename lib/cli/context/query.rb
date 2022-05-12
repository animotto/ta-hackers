# frozen_string_literal: true

require 'base64'
require 'json'

DUMPS_DIR = File.join(BASE_DIR, 'dumps')
DUMPS_EXT = '.dump'

QUERY_DUMPS = []

## Commands

# qr
CONTEXT_QUERY.add_command(
  :qr,
  description: 'Raw query',
  params: ['<args>']
) do |tokens, shell|
  data = {}
  tokens[1..-1].each do |token|
    GAME.config.each do |k, v|
      token.gsub!("%#{k}%", v.to_s)
    end
    param = token.split('=', 2)
    data[param[0]] = param.length > 1 ? param[1] : ''
  end

  uri = GAME.client.encodeURI(data)
  query = GAME.client.makeURI(uri, GAME.sid, false, false)

  msg = "Query: #{query}"
  response = GAME.client.request(data, GAME.sid, false, false)
  LOGGER.log(msg)
  shell.puts("\e[22;35m#{response}\e[0m")

  QUERY_DUMPS.append(
    {
      :name => "Dump#{QUERY_DUMPS.length}",
      :note => '',
      :datetime => Time.now.to_s,
      :query => query,
      :data => Base64.encode64(response)
    }
  )
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# qc
CONTEXT_QUERY.add_command(
  :qc,
  description: 'Hashed query',
  params: ['<args>']
) do |tokens, shell|
  data = {}
  tokens[1..-1].each do |token|
    GAME.config.each do |k, v|
      token.gsub!("%#{k}%", v.to_s)
    end
    param = token.split('=', 2)
    data[param[0]] = param.length > 1 ? param[1] : ''
  end

  uri = GAME.client.encodeURI(data)
  query = GAME.client.makeURI(uri, GAME.sid, true, false)

  msg = "Query: #{query}"
  response = GAME.client.request(data, GAME.sid, true, false)
  LOGGER.log(msg)
  shell.puts("\e[22;35m#{response}\e[0m")

  QUERY_DUMPS.append(
    {
      :name => "Dump#{QUERY_DUMPS.length}",
      :note => '',
      :datetime => Time.now.to_s,
      :query => query,
      :data => Base64.encode64(response)
    }
  )
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# qs
CONTEXT_QUERY.add_command(
  :qs,
  description: 'Session query',
  params: ['<args>']
) do |tokens, shell|
  if GAME.sid.empty?
    shell.puts('No session ID')
    next
  end

  data = {}
  tokens[1..-1].each do |token|
    GAME.config.each do |k, v|
      token.gsub!("%#{k}%", v.to_s)
    end
    param = token.split('=', 2)
    data[param[0]] = param.length > 1 ? param[1] : ''
  end

  uri = GAME.client.encodeURI(data)
  query = GAME.client.makeURI(uri, GAME.sid, true, true)

  msg = "Query: #{query}"
  response = GAME.client.request(data, GAME.sid, true, true)
  LOGGER.log(msg)
  shell.puts("\e[22;35m#{response}\e[0m")

  QUERY_DUMPS.append(
    {
      :name => "Dump#{QUERY_DUMPS.length}",
      :note => '',
      :datetime => Time.now.to_s,
      :query => query,
      :data => Base64.encode64(response)
    }
  )
rescue Trickster::Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# dumps
CONTEXT_QUERY.add_command(
  :dumps,
  description: 'List dumps'
) do |tokens, shell|
  if QUERY_DUMPS.empty?
    shell.puts('No dumps')
    next
  end

  shell.puts("Dumps:")
  QUERY_DUMPS.each_with_index do |dump, i|
    shell.puts(
      format(
        '[%d] %s: %s',
        i,
        dump[:datetime],
        dump[:name]
      )
    )
  end
end

# show
CONTEXT_QUERY_SHOW = CONTEXT_QUERY.add_command(
  :show,
  description: 'Show dump',
  params: ['<id>']
) do |tokens, shell|
  id = tokens[1].to_i
  if QUERY_DUMPS[id].nil?
    shell.puts('No such dump')
    next
  end

  QUERY_DUMPS[id].each do |k, v|
    value = k == :data ? Base64.decode64(v) : v
    shell.puts("\e[1;32m#{k.capitalize}: \e[22;36m#{value}\e[0m")
  end
end

CONTEXT_QUERY_SHOW.completion do
  list = []
  list += (0..(QUERY_DUMPS.length - 1)).to_a.map(&:to_s) unless QUERY_DUMPS.empty?
  list
end

# del
CONTEXT_QUERY_DEL = CONTEXT_QUERY.add_command(
  :del,
  description: 'Delete dump',
  params: ['<id>']
) do |tokens, shell|
  id = tokens[1].to_i
  if QUERY_DUMPS[id].nil?
    shell.puts('No such dump')
    next
  end

  QUERY_DUMPS.delete_at(id)
  shell.puts("Dump #{id} has been deleted")
end

CONTEXT_QUERY_DEL.completion do
  list = []
  list += (0..(QUERY_DUMPS.length - 1)).to_a.map(&:to_s) unless QUERY_DUMPS.empty?
  list
end

# rename
CONTEXT_QUERY_RENAME = CONTEXT_QUERY.add_command(
  :rename,
  description: 'Rename dump',
  params: ['<id>', '<name>']
) do |tokens, shell|
  id = tokens[1].to_i
  if QUERY_DUMPS[id].nil?
    shell.puts('No such dump')
    next
  end

  name = tokens[2..-1].join(' ')
  QUERY_DUMPS[id][:name] = name
  shell.puts("Dump #{id} has been renamed")
end

CONTEXT_QUERY_RENAME.completion do
  list = []
  list += (0..(QUERY_DUMPS.length - 1)).to_a.map(&:to_s) unless QUERY_DUMPS.empty?
  list
end

# note
CONTEXT_QUERY_NOTE = CONTEXT_QUERY.add_command(
  :note,
  description: 'Set a note for the dump',
  params: ['<id>', '<name>']
) do |tokens, shell|
  id = tokens[1].to_i
  if QUERY_DUMPS[id].nil?
    shell.puts('No such dump')
    next
  end

  note = tokens[2..-1].join(' ')
  QUERY_DUMPS[id][:note] = note
  shell.puts("Dump note #{id} has been setted")
end

CONTEXT_QUERY_NOTE.completion do
  list = []
  list += (0..(QUERY_DUMPS.length - 1)).to_a.map(&:to_s) unless QUERY_DUMPS.empty?
  list
end

# list
CONTEXT_QUERY.add_command(
  :list,
  description: 'List dump files'
) do |tokens, shell|
  files = []
  Dir.children(DUMPS_DIR).sort.each do |child|
    next unless File.file?(File.join(DUMPS_DIR, child)) && child.end_with?(DUMPS_EXT)
    child.delete_suffix!(DUMPS_EXT)
    files << child
  end

  if files.empty?
    shell.puts('No dump files')
    next
  end

  shell.puts('Dump files:')
  files.each do |file|
    shell.puts(" #{file}")
  end
end

# export
CONTEXT_QUERY_EXPORT = CONTEXT_QUERY.add_command(
  :export,
  description: 'Export dumps to the file',
  params: ['<file>']
) do |tokens, shell|
  if QUERY_DUMPS.empty?
    shell.puts('No dumps')
    next
  end

  file = File.join(DUMPS_DIR, "#{tokens[1]}#{DUMPS_EXT}")
  File.write(file, JSON.generate(QUERY_DUMPS))
  shell.puts("Dumps have been exported to file #{tokens[1]}")
end

CONTEXT_QUERY_EXPORT.completion do
  list = Dir.children(DUMPS_DIR).select { |f| File.file?(File.join(DUMPS_DIR, f)) && f.end_with?(DUMPS_EXT) }
  list.map { |f| f.delete_suffix(DUMPS_EXT) }
end

# import
CONTEXT_QUERY_IMPORT = CONTEXT_QUERY.add_command(
  :import,
  description: 'Import dumps from the file',
  params: ['<file>']
) do |tokens, shell|
  file = File.join(DUMPS_DIR, "#{tokens[1]}#{DUMPS_EXT}")
  unless File.file?(file)
    shell.puts('No such file')
    next
  end

  dump = JSON.parse(File.read(file), symbolize_names: true)
  QUERY_DUMPS.clear
  QUERY_DUMPS.concat(dump)
  shell.puts("Dumps have been imported from file #{tokens[1]}")
rescue JSON::ParserError
  shell.puts('Invalid dump format')
end

CONTEXT_QUERY_IMPORT.completion do
  list = Dir.children(DUMPS_DIR).select { |f| File.file?(File.join(DUMPS_DIR, f)) && f.end_with?(DUMPS_EXT) }
  list.map { |f| f.delete_suffix(DUMPS_EXT) }
end

# rm
CONTEXT_QUERY_RM = CONTEXT_QUERY.add_command(
  :rm,
  description: 'Delete dump file',
  params: ['<file>']
) do |tokens, shell|

  file = File.join(DUMPS_DIR, "#{tokens[1]}#{DUMPS_EXT}")
  unless File.file?(file)
    shell.puts('No such file')
    next
  end

  File.delete(file)
  shell.puts("Dumps file #{tokens[1]} has been deleted")
end

CONTEXT_QUERY_RM.completion do
  list = Dir.children(DUMPS_DIR).select { |f| File.file?(File.join(DUMPS_DIR, f)) && f.end_with?(DUMPS_EXT) }
  list.map { |f| f.delete_suffix(DUMPS_EXT) }
end
