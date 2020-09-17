module Sandbox
  class ContextScript < ContextBase
    SCRIPTS_DIR = "scripts"

    def initialize(game, shell)
      super(game, shell)
      @commands.merge!({
                         "run" => ["run <name>", "Run the script"],
                         "list" => ["list", "List scripts"],
                         "jobs" => ["jobs", "List active scripts"],
                         "kill" => ["kill <id>", "Kill the script"],
                         "admin" => ["admin <id>", "Administrate the script"],
                       })
      @jobs = Hash.new
      @jobCounter = 0;
      @logger = Logger.new(@shell)
      @logger.logPrefix = "\e[1;34m\u273f\e[22;34m "
      @logger.logSuffix = "\e[0m"
      @logger.errorPrefix = "\e[1;31m\u273f\e[22;31m "
      @logger.errorSuffix = "\e[0m"
    end

    def exec(words)
      cmd = words[0].downcase
      case cmd

      when "run"
        script = words[1]
        if script.nil?
          @shell.puts("#{cmd}: Specify script name")
          return
        end

        fname = "#{SCRIPTS_DIR}/#{script}.rb"
        unless File.exists?(fname)
          @shell.puts("#{cmd}: No such script")
          return
        end

        Thread.new {run(script, words[2..-1])}
        return

      when "list"
        scripts = Array.new
        Dir.children(SCRIPTS_DIR).sort.each do |child|
          next unless File.file?("#{SCRIPTS_DIR}/#{child}") && child =~ /\.rb$/
          child.sub!(".rb", "")
          scripts.append(child)
        end

        if scripts.empty?
          @shell.puts("#{cmd}: No scripts")
          return
        end

        @shell.puts("Scripts:")
        scripts.each do |script|
          @shell.puts(" #{script}")
        end
        return

      when "jobs"
        if @jobs.empty?
          @shell.puts("#{cmd}: No active jobs")
          return
        end

        @shell.puts("Active jobs:")
        @jobs.each do |k, v|
          @shell.puts(" [%d] %s" % [k, v["script"]])
        end
        return

      when "kill"
        if words[1].nil?
          @shell.puts("#{cmd}: Specify job ID")
          return
        end

        job = words[1].to_i
        unless @jobs.key?(job)
          @shell.puts("#{cmd}: No such job")
          return
        end

        @logger.log("Killed: #{@jobs[job]["script"]} [#{job}]")
        @jobs[job]["thread"].kill
        script = @jobs[job]["script"]
        name = script.capitalize
        @jobs.delete(job)
        Object.send(:remove_const, name) unless @jobs.each_value.detect {|j| j["script"] == script}
        return
        
      when "admin"
        if words[1].nil?
          @shell.puts("#{cmd}: Specify job ID")
          return
        end

        job = words[1].to_i
        unless @jobs.key?(job)
          @shell.puts("#{cmd}: No such job")
          return
        end

        unless @jobs[job]["instance"].respond_to?("admin")
          @shell.puts("#{cmd}: Not implemented")
          return
        end

        @shell.puts("Enter ! to quit")
        loop do
          prompt = "\e[1;34m#{@jobs[job]["script"]}:#{job} \u273f\e[0m "
          @shell.reading = true
          line = Readline.readline(prompt, true)
          @shell.reading = false
          break if line.nil?
          line.strip!
          Readline::HISTORY.pop if line.empty?
          next if line.empty?
          break if line == "!"
          msg = @jobs[job]["instance"].admin(line)
          next if msg.nil? || msg.empty?
          @shell.puts(msg)
        end
        return

      end
            
      super(words)
    end

    def run(script, args)
      job = @jobCounter += 1
      @jobs[job] = {
        "script" => script,
        "thread" => Thread.current,
      }
      fname = "#{SCRIPTS_DIR}/#{script}.rb"
      @logger.log("Run: #{script} [#{job}]")
      
      logger = Logger.new(@shell)
      logger.logPrefix = "\e[1;36m\u276f [#{script}]\e[22;36m "
      logger.logSuffix = "\e[0m"
      logger.errorPrefix = "\e[1;31m\u276f [#{script}]\e[22;31m "
      logger.errorSuffix = "\e[0m"
      logger.infoPrefix = "\e[1;37m\u276f [#{script}]\e[22;37m "
      logger.errorSuffix = "\e[0m"

      begin
        name = script.capitalize
        load "#{fname}" unless Object.const_defined?(name)
        eval(%Q[@jobs[#{job}]["instance"] = #{name}.new(@game, @shell, logger, args)])
        @jobs[job]["instance"].main
      rescue => e
        msg = String.new
        (e.backtrace.length - 1).downto(0) do |i|
          msg += "#{i + 1}. #{e.backtrace[i]}\n"
        end
        @logger.error("Error: #{script} [#{job}]\n\n#{msg}\n=> #{e.message}")
      else
        @logger.log("Done: #{script} [#{job}]")
      end

      @jobs.delete(job)
      Object.send(:remove_const, name) if !@jobs.each_value.detect {|j| j["script"] == script} && Object.const_defined?(name)
    end
  end
end

