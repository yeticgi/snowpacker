class UnityProject < UnityManagedProject
  attr_accessor :core_project,
    :first_pass_project,
    :editor_project

  def initialize(name, &block)
    @core_project = CoreProject.new "#{name}.Core", self
    @first_pass_project = UnityFirstPassProject.new self, @core_project
    @dependencies = [@first_pass_project]
    super name, &block
  end

  def project_name
    "Assembly-CSharp"
  end
end

