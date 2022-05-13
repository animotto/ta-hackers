# frozen_string_literal: true

SCRIPT_DIR = File.join(BASE_DIR, 'scripts')
SCRIPT_EXT = '.rb'

SCRIPT_JOBS = {}
SCRIPT_VARS = {
  job_counter: 0
}

SCRIPT_LOGGER = Sandbox::Logger.new(SHELL)
SCRIPT_LOGGER.logPrefix = "\e[1;34m\u273f\e[22;34m "
SCRIPT_LOGGER.logSuffix = "\e[0m"
SCRIPT_LOGGER.errorPrefix = "\e[1;31m\u273f\e[22;31m "
SCRIPT_LOGGER.errorSuffix = "\e[0m"

def script_run(shell, script, args)
  job = SCRIPT_VARS[:job_counter] += 1
  SCRIPT_JOBS[job] = {
    script: script,
    thread: Thread.current
  }

  file = File.join(SCRIPT_DIR, "#{script}#{SCRIPT_EXT}")

  logger = Sandbox::Logger.new(shell)
  logger.logPrefix = "\e[1;36m\u276f [#{script}]\e[22;36m "
  logger.logSuffix = "\e[0m"
  logger.errorPrefix = "\e[1;31m\u276f [#{script}]\e[22;31m "
  logger.errorSuffix = "\e[0m"
  logger.infoPrefix = "\e[1;37m\u276f [#{script}]\e[22;37m "
  logger.errorSuffix = "\e[0m"

  begin
    name = script.capitalize
    load file unless Object.const_defined?(name)
    raise "Class #{name} not found" unless Object.const_defined?(name)

    SCRIPT_JOBS[job][:instance] = Object.const_get(name).new(GAME, shell, logger, args)
    SCRIPT_LOGGER.log("Run: #{script} [#{job}]")
    SCRIPT_JOBS[job][:instance].main
    SCRIPT_JOBS[job][:instance].finish
    SCRIPT_LOGGER.log("Done: #{script} [#{job}]")
  rescue StandardError => e
    script_log_backtrace(script, job, e)
  end

  SCRIPT_JOBS.delete(job)
  return if SCRIPT_JOBS.values.detect { |j| j[:script] == script }

  Object.send(:remove_const, name) if Object.const_defined?(name)
end

def script_log_backtrace(script, job, e)
  msg = String.new
  (e.backtrace.length - 1).downto(0) do |i|
    msg += "#{i + 1}. #{e.backtrace[i]}\n"
  end

  SCRIPT_LOGGER.error("Error: #{script} [#{job}]\n\n#{msg}\n=> #{e.message}")
end

## Commands

# run
CONTEXT_SCRIPT_RUN = CONTEXT_SCRIPT.add_command(
  :run,
  description: 'Run the script',
  params: ['<name>']
) do |tokens, shell|
  script = tokens[1]

  file = File.join(SCRIPT_DIR, "#{script}#{SCRIPT_EXT}")
  unless File.file?(file)
    shell.puts('No such script')
    next
  end

  Thread.new { script_run(shell, script, tokens[2..]) }
end

CONTEXT_SCRIPT_RUN.completion do |line|
  files = Dir.children(SCRIPT_DIR).select { |f| f.end_with?(SCRIPT_EXT) }
  files.map! { |f| f.delete_suffix(SCRIPT_EXT) }
  files.grep(/^#{Regexp.escape(line)}/)
end

# list
CONTEXT_SCRIPT.add_command(
  :list,
  description: 'List scripts'
) do |tokens, shell|
  scripts = []
  Dir.children(SCRIPT_DIR).sort.each do |child|
    file = File.join(SCRIPT_DIR, child)
    next unless File.file?(file) && child.end_with?(SCRIPT_EXT)

    child.delete_suffix!(SCRIPT_EXT)
    scripts << child
  end

  if scripts.empty?
    shell.puts('No scripts')
    next
  end

  shell.puts('Scripts:')
  scripts.each do |script|
    shell.puts(" #{script}")
  end
end

# jobs
CONTEXT_SCRIPT.add_command(
  :jobs,
  description: 'List active scripts'
) do |tokens, shell|
  if SCRIPT_JOBS.empty?
    shell.puts('No active jobs')
    next
  end

  shell.puts('Active jobs:')
  SCRIPT_JOBS.each do |k, v|
    shell.puts(format(' [%d] %s', k, v[:script]))
  end
end

# kill
CONTEXT_SCRIPT_KILL = CONTEXT_SCRIPT.add_command(
  :kill,
  description: 'Kill the script',
  params: ['<id>']
) do |tokens, shell|
  job = tokens[1].to_i

  unless SCRIPT_JOBS.key?(job)
    shell.puts('No such job')
    next
  end

  begin
    SCRIPT_JOBS[job][:instance].finish
  rescue StandardError => e
    script_log_backtrace(script, job, e)
  end

  SCRIPT_JOBS[job][:thread].kill
  SCRIPT_LOGGER.log("Killed: #{SCRIPT_JOBS[job][:script]} [#{job}]")
  script = SCRIPT_JOBS[job][:script]
  name = script.capitalize
  SCRIPT_JOBS.delete(job)
  Object.send(:remove_const, name) unless SCRIPT_JOBS.each_value.detect { |j| j[:script] == script }
end

CONTEXT_SCRIPT_KILL.completion do |line|
  jobs = SCRIPT_JOBS.keys.map(&:to_s)
  jobs.grep(/^#{Regexp.escape(line)}/)
end

# admin
CONTEXT_SCRIPT_ADMIN = CONTEXT_SCRIPT.add_command(
  :admin,
  description: 'Administrate the script',
  params: ['<id>']
) do |tokens, shell|
  job = tokens[1].to_i

  unless SCRIPT_JOBS.key?(job)
    shell.puts('No such job')
    next
  end

  unless SCRIPT_JOBS[job][:instance].respond_to?(:admin)
    shell.puts('Not implemented')
    next
  end

  shell.puts('Enter ! or ^D to quit')
  prompt = "\e[1;34m#{SCRIPT_JOBS[job][:script]}:#{job} \u273f\e[0m "
  loop do
    line = shell.readline(prompt, true)
    if line.nil?
      shell.puts
      break
    end

    line.strip!
    next if line.empty?

    break if line == '!'

    unless SCRIPT_JOBS.key?(job)
      SCRIPT_LOGGER.error("Job #{job} was terminated")
      break
    end

    msg = SCRIPT_JOBS[job][:instance].admin(line)
    next if msg.nil? || msg.empty?

    shell.puts(msg)
  end
end

CONTEXT_SCRIPT_ADMIN.completion do |line|
  jobs = SCRIPT_JOBS.keys.map(&:to_s)
  jobs.grep(/^#{Regexp.escape(line)}/)
end
