module Sandbox
  class ContextQuery < ContextBase
    DUMPS_DIR = "dumps"

    def initialize(game, shell)
      super(game, shell)
      @commands.merge!({
                         "qr" => ["qr <arg1> .. <argN>", "Raw query"],
                         "qc" => ["qc <arg1> .. <argN>", "Hashed query"],
                         "qs" => ["qs <arg1> .. <argN>", "Session query"],
                         "dumps" => ["dumps", "List dumps"],
                         "show" => ["show <id>", "Show dump"],
                         "del" => ["del <id>", "Delete dump"],
                         "rename" => ["rename <id> <name>", "Rename dump"],
                         "note" => ["note <id> <name>", "Set a note for the dump"],
                         "list" => ["list", "List dump files"],
                         "export" => ["export <file>", "Export dumps to the file"],
                         "import" => ["import <file>", "Import dumps from the file"],
                         "rm" => ["rm <file>", "Delete dump file"],
                       })
      @dumps = Array.new
    end
    
    def exec(words)
      cmd = words[0].downcase
      case cmd
          
      when "qr", "qc", "qs"
        data = Hash.new
        words[1..-1].each do |word|
          @game.config.each do |k, v|
            word.gsub!("%#{k}%", v.to_s)
          end
          param = word.split("=", 2)
          data[param[0]] = param.length > 1 ? param[1] : ""
        end
        
        url = @game.encodeUrl(data)
        if cmd == "qs" && @game.sid.empty?
          @shell.puts "#{cmd}: No session ID"
          return
        end

        query = @game.makeUrl(url, (cmd == "qc" || cmd == "qs"), (cmd == "qs"))
        msg = "Query: #{query}"
        begin
          response = @game.request(url, (cmd == "qc" || cmd == "qs"), (cmd == "qs"))
        rescue Trickster::Hackers::RequestError => e
          @shell.logger.error("#{msg} (#{e})")
          return          
        end

        @shell.logger.log(msg)
        @shell.puts("\e[22;35m#{response}\e[0m")
        @dumps.append({
                        "name" => "Dump#{@dumps.length}",
                        "note" => "",
                        "datetime" => Time.now.to_s,
                        "query" => query,
                        "data" => Base64.encode64(response),
                      })
        return

      when "dumps"
        if @dumps.empty?
          @shell.puts("#{cmd}: No dumps")
          return
        end

        @shell.puts("Dumps:")
        @dumps.each_index do |i|
          @shell.puts(
            "[%d] %s: %s" % [
              i, @dumps[i]["datetime"], @dumps[i]["name"]
            ]
          )
        end
        return

      when "show"
        if words[1].nil?
          @shell.puts("#{cmd}: Specify dump ID")
          return
        end
        
        id = words[1].to_i
        if @dumps[id].nil?
          @shell.puts("#{cmd}: No such dump")
          return
        end

        @dumps[id].each do |k, v|
          if k == "data"
            val = Base64.decode64(v)
          else
            val = v
          end
          @shell.puts("\e[1;32m#{k.capitalize}: \e[22;36m#{val}\e[0m")
        end
        return

      when "del"
        if words[1].nil?
          @shell.puts("#{cmd}: Specify dump ID")
          return
        end
        
        id = words[1].to_i
        if @dumps[id].nil?
          @shell.puts("#{cmd}: No such dump")
          return
        end

        @dumps.delete_at(id)
        return        

      when "rename"
        if words[1].nil?
          @shell.puts("#{cmd}: Specify dump ID")
          return
        end
        
        id = words[1].to_i
        if @dumps[id].nil?
          @shell.puts("#{cmd}: No such dump")
          return
        end

        name = words[2..-1].join(" ")
        if name.nil? || name.empty?
          @shell.puts("#{cmd}: Specify dump name")
          return
        end

        @dumps[id]["name"] = name
        return

      when "note"
        if words[1].nil?
          @shell.puts("#{cmd}: Specify dump ID")
          return
        end
        
        id = words[1].to_i
        if @dumps[id].nil?
          @shell.puts("#{cmd}: No such dump")
          return
        end

        note = words[2..-1].join(" ")
        if note.nil? || note.empty?
          @shell.puts("#{cmd}: Specify dump note")
          return
        end

        @dumps[id]["note"] = note
        return
        
      when "list"
        files = Array.new
        Dir.children("#{DUMPS_DIR}").sort.each do |child|
          next unless File.file?("#{DUMPS_DIR}/#{child}") && child =~ /\.dump$/
          child.sub!(".dump", "")
          files.append(child)
        end

        if files.empty?
          @shell.puts("#{cmd}: No dump files")
          return
        end

        @shell.puts("Dump files:")
        files.each do |file|
          @shell.puts(" #{file}")
        end
        return
        
      when "export"
        file = words[1]
        if file.nil?
          @shell.puts("#{cmd}: Specify file name")
          return
        end

        if @dumps.empty?
          @shell.puts("#{cmd}: No dumps")
          return
        end
        
        File.write("#{DUMPS_DIR}/#{file}.dump", JSON::generate(@dumps))
        return

      when "import"
        file = words[1]
        if file.nil?
          @shell.puts("#{cmd}: Specify file name")
          return
        end

        fname = "#{DUMPS_DIR}/#{file}.dump"
        unless File.exists?(fname)
          @shell.puts("#{cmd}: No such file")
          return
        end

        dump = File.read(fname)
        begin
          @dumps = JSON::parse(dump)
        rescue JSON::ParserError => e
          @shell.puts("#{cmd}: Invalid dump format")
          @shell.puts
          @shell.puts(e)
        end
        return

      when "rm"
        file = words[1]
        if file.nil?
          @shell.puts("#{cmd}: Specify file name")
          return
        end

        fname = "#{DUMPS_DIR}/#{file}.dump"
        unless File.exists?(fname)
          @shell.puts("#{cmd}: No such file")
          return
        end

        File.delete(fname)
        return
        
      end
      
      super(words)
    end
  end
end

