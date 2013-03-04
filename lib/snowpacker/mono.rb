module Mono
  class << self
    Location = if OS.windows?
                 OS.cygpath "C:\\Program Files (x86)\\Mono-2.10.9\\bin\\mono.exe"
               else
                 "mono"
               end
    
    def run(command, opts = {})
      system "'#{Location}' --runtime=v4.0 #{command}"
    end
  end
end

