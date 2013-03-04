class CoreProject < Project
  attr_accessor :unity_project

  def initialize(name, unity_project, &block)
    @unity_project = unity_project
    # @dependencies = [Project["Snowball"]]
    super name, &block
  end

  def dll(configuration = nil)
    "#{unity_project.plugins}/#{name}.dll"
  end
end

