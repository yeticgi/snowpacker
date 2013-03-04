class Project
  List = []

  class << self
    def [](name)
      List.detect { |p| p.name == name }
    end
  end

  attr_accessor :name,
    :dependencies

  def initialize(name, opts = {}, &block)
    @name = name
    @dir = opts[:dir]
    @solution_name = opts[:solution_name]

    @dependencies ||= []

    self.instance_exec &block if block

    List << self
  end    

  def configurations
    ["Debug", "Release"]
  end

  def default_configuration
    "Release"
  end

  def dir
    @dir || name
  end

  def solution_name
    @solution_name || name
  end

  def solution
    "#{dir}/#{solution_name}.sln"
  end

  def absolute_dll(configuration = default_configuration)
    File.expand_path dll(configuration)
  end

  def dll(configuration = default_configuration)
    "#{dll_dir configuration}/#{dll_name}"
  end

  def dll_dir(configuration = default_configuration)
    "#{project_dir}/bin/#{configuration}"
  end

  def dll_name
    "#{project_name}.dll"
  end

  def project_dir
    "#{dir}/#{project_name}"
  end

  def project_name
    name
  end

  def packages
    REXML::Document.new(File.new(package_config)).elements.enum_for(:each, "packages/package").map do |package|
      {
        :id => package.attributes["id"],
        :version => package.attributes["version"]
      }
    end
  end

  def package_dir
    "#{dir}/packages"
  end

  def package_config
    "#{source_dir}/packages.config"
  end

  def absolute_installed_package_dir_for(package)
    File.expand_path installed_package_dir_for(package)
  end

  def installed_package_dir_for(package)
    "#{package_dir}/#{NuGet.package_dir package}"
  end

  def absolute_installed_package_dirs
    installed_package_dirs.map do |dir|
      File.expand_path dir
    end
  end    

  def installed_package_dirs
    packages.map do |package|
      installed_package_dir_for package
    end
  end

  def local_packages
    packages.select do |package|
      Project::List.any? { |p| p.name == package[:id] }
    end
  end

  def local_package_files
    local_packages.map do |package|
      local_package_file_for package
    end
  end

  def local_package_file_for(package)
    Project[package[:id]].package_file
  end

  def dependency_dlls(configuration = default_configuration)
    dependencies.map do |dependency|
      dependency.dll configuration
    end
  end

  def absolute_dependency_dlls(configuration = default_configuration)
    dependency_dlls(configuration).map do |dependency|
      File.expand_path dependency
    end
  end

  def source_dir
    "#{dir}/#{name}"
  end

  def sources
    Dir.glob "#{source_dir}/*.cs"
  end

  def absolute_sources
    sources.map do |source|
      File.expand_path source
    end
  end

  def install_package(package)
    NuGet.install_package package, package_dir, project_dir
  end

  def install_packages(packages)
    NuGet.install_packages packages, package_dir, project_dir
  end

  def build
    MDTool.build solution, project: project_name, configuration: default_configuration
  end

  def install_all_packages
    install_packages packages
  end

  def namespace
    name.downcase
  end

  def clean_packages_task
    "#{namespace}:packages:clean"
  end

  def define_clean_packages_task
    Rake::Task.define_task clean_packages_task do
      FileUtils.rm_rf package_dir
    end
  end

  def check_packages_task
    "#{namespace}:packages:check"
  end

  def define_check_packages_task
    Rake::Task.define_task check_packages_task do
      install_prereqs = Rake::Task[install_packages_task].prerequisites.map do |prereq|
        Rake::FileTask[prereq]
      end

      if install_prereqs.any? &:invoke
        Rake::Task[install_packages_task].invoke
      end
    end
  end  

  def install_packages_task
    "#{namespace}:packages:install"
  end

  def define_install_packages_task
    package_dependencies = packages.map do |package|
      if local_packages.include? package
        local_package_file_for package
      end
    end.compact

    packages.each do |package|
      installed_package_dir = absolute_installed_package_dir_for package

      unless Rake::FileTask.task_defined? installed_package_dir
        Rake::FileTask.define_task installed_package_dir => package_dependencies do
          Rake::Task[install_packages_task].invoke
        end
      end
    end

    Rake::Task.define_task install_packages_task => package_dependencies do
      install_all_packages
    end
  end

  def clean_task(configuration = nil)
    "#{namespace}:clean#{":#{configuration.downcase}" if configuration}"
  end

  def define_clean_task(configuration = default_configuration)
    Rake::Task.define_task clean_task(configuration) do
      FileUtils.rm absolute_dll(configuration) rescue nil
      Rake::Task[clean_packages_task].invoke
    end
  end

  def define_clean_tasks
    configurations.each do |configuration|
      define_clean_task configuration
    end
    Rake::Task.define_task clean_task => configurations.map { |c| clean_task(c) }
  end

  def build_task(configuration = nil)
    "#{namespace}:build#{":#{configuration.downcase}" if configuration}"
  end

  def define_build_task(configuration = default_configuration)
    dependencies = absolute_installed_package_dirs + local_package_files + absolute_dependency_dlls(configuration) + absolute_sources

    Rake::Task.define_task build_task(configuration) => dependencies do
      build
    end

    Rake::FileTask.define_task absolute_dll(configuration) => dependencies do
      Rake::Task[build_task(configuration)].invoke
    end
  end

  def define_build_tasks
    configurations.each do |configuration|
      define_build_task configuration
    end
    Rake::Task.define_task build_task => build_task(default_configuration)
  end

  def define_tasks
    define_clean_packages_task
    define_install_packages_task
    define_check_packages_task

    define_clean_tasks
    define_build_tasks
  end

  def scan_snowpacked_packages
    snowpacked_packages = packages.map do |package|
      local_dir = NuGet.local_package_dir package
      if local_dir
        [package, local_dir]
      end
    end.compact

    if snowpacked_packages.any?
      snowpacked_packages.each do |package, local_dir|
        rakefile = "#{local_dir}/Rakefile"
        unless $".include? rakefile
          load rakefile
          $" << rakefile
        end
      end
    end
  end
end

