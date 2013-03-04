class UnityFirstPassProject < UnityManagedProject
  attr_accessor :unity_project,
    :core_project

  def initialize(unity_project, core_project, &block)
    @unity_project = unity_project
    @core_project = core_project
    # @dependencies = [core_project, Project["Snowball.Unity"]]
    super nil, &block
  end

  def name
    "#{unity_project.name}-firstpass"
  end

  def solution_name
    unity_project.solution_name
  end

  def dir
    unity_project.dir
  end

  def project_name
    "Assembly-CSharp-firstpass"
  end
end

