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
  params = {}
  tokens[1..].each do |token|
    GAME.config.each do |k, v|
      token.gsub!("%#{k}%", v.to_s)
    end
    param = token.split('=', 2)
    params[param[0]] = param.length > 1 ? param[1] : ''
  end

  client = GAME.api.client
  query = client.generate_uri_raw(params.clone)

  msg = "Query: #{query}"
  response = client.request_raw(params)
  LOGGER.log(msg)
  shell.puts(ColorTerm.magenta(response))

  QUERY_DUMPS.append(
    {
      name: "Dump#{QUERY_DUMPS.length}",
      note: '',
      datetime: Time.now.to_s,
      query: query,
      data: Base64.encode64(response)
    }
  )
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# qc
CONTEXT_QUERY.add_command(
  :qc,
  description: 'Hashed query',
  params: ['<args>']
) do |tokens, shell|
  params = {}
  tokens[1..].each do |token|
    GAME.config.each do |k, v|
      token.gsub!("%#{k}%", v.to_s)
    end
    param = token.split('=', 2)
    params[param[0]] = param.length > 1 ? param[1] : ''
  end

  client = GAME.api.client
  query = client.generate_uri_cmd(params.clone)

  msg = "Query: #{query}"
  response = client.request_cmd(params)
  LOGGER.log(msg)
  shell.puts(ColorTerm.magenta(response))

  QUERY_DUMPS.append(
    {
      name: "Dump#{QUERY_DUMPS.length}",
      note: '',
      datetime: Time.now.to_s,
      query: query,
      data: Base64.encode64(response)
    }
  )
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# qs
CONTEXT_QUERY.add_command(
  :qs,
  description: 'Session query',
  params: ['<args>']
) do |tokens, shell|
  unless GAME.connected?
    shell.puts(NOT_CONNECTED)
    next
  end

  params = {}
  tokens[1..].each do |token|
    GAME.config.each do |k, v|
      token.gsub!("%#{k}%", v.to_s)
    end
    param = token.split('=', 2)
    params[param[0]] = param.length > 1 ? param[1] : ''
  end

  client = GAME.api.client
  query = client.generate_uri_session(params.clone, GAME.api.sid)

  msg = "Query: #{query}"
  response = client.request_session(params, GAME.api.sid)
  LOGGER.log(msg)
  shell.puts(ColorTerm.magenta(response))

  QUERY_DUMPS.append(
    {
      name: "Dump#{QUERY_DUMPS.length}",
      note: '',
      datetime: Time.now.to_s,
      query: query,
      data: Base64.encode64(response)
    }
  )
rescue Hackers::RequestError => e
  LOGGER.error("#{msg} (#{e})")
end

# dumps
CONTEXT_QUERY.add_command(
  :dumps,
  description: 'List dumps'
) do |_tokens, shell|
  if QUERY_DUMPS.empty?
    shell.puts('No dumps')
    next
  end

  shell.puts('Dumps:')
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
    shell.puts("#{ColorTerm.bold.green(k.capitalize)}: #{ColorTerm.cyan(value)}")
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

  next unless shell.confirm('Are you sure?')

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

  name = tokens[2..].join(' ')
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

  note = tokens[2..].join(' ')
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
) do |_tokens, shell|
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

  next unless shell.confirm('Are you sure?')

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

  next unless shell.confirm('Are you sure?')

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

  next unless shell.confirm('Are you sure?')

  File.delete(file)
  shell.puts("Dumps file #{tokens[1]} has been deleted")
end

CONTEXT_QUERY_RM.completion do
  list = Dir.children(DUMPS_DIR).select { |f| File.file?(File.join(DUMPS_DIR, f)) && f.end_with?(DUMPS_EXT) }
  list.map { |f| f.delete_suffix(DUMPS_EXT) }
end

# format
CONTEXT_QUERY_FORMAT = CONTEXT_QUERY.add_command(
  :format,
  description: 'Print formatted dump data',
  params: ['<id>', '[section]', '[record]']
) do |tokens, shell|
  id = tokens[1].to_i
  if QUERY_DUMPS[id].nil?
    shell.puts('No such dump')
    next
  end

  serializer = Hackers::Serializer::Base.new(Base64.decode64(QUERY_DUMPS[id][:data]))

  serializer.fields.each_with_index do |section, i|
    next if !tokens[2].nil? && tokens[2].to_i != i

    shell.puts("{#{i}}")
    section.each_with_index do |record, j|
      next if !tokens[3].nil? && tokens[3].to_i != j

      shell.puts(" (#{j})")
      record.each_with_index do |field, k|
        shell.puts("  [#{k}] #{field}")
      end
    end
  end
end

CONTEXT_QUERY_FORMAT.completion do
  list = []
  list += (0..(QUERY_DUMPS.length - 1)).to_a.map(&:to_s) unless QUERY_DUMPS.empty?
  list
end
