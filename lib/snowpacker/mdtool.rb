module MDTool
  class << self
    Location = if OS.windows?
                 '"C:\\Program Files (x86)\\MonoDevelop\\bin\\mdtool.exe"'
               else
                 ["Xamarin Studio", "MonoDevelop"].map { |ide| "/Applications/#{ide}.app/Contents/MacOS/mdtool" }.detect { |file| File.exists? file }
               end

    def build(solution_file, opts = {})
      run_target solution_file, "Build", opts
    end

    def clean(solution_file, opts = {})
      run_target solution_file, "Clean", opts
    end
      
    def run_target(solution_file, target = "Build", opts = {})
      raise "no configuration specified" unless opts[:configuration]
      raise "no project specified" unless opts[:project]

      command = "'#{Location}' build '-t:#{target}' '-c:#{opts[:configuration]}' '-p:#{opts[:project]}' '#{solution_file}'"

      if OS.windows?
        Mono.run command
      else
        system command
      end
    end
  end
end

