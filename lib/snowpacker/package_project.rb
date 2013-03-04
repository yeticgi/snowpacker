class PackageProject < Project
  def initialize(name, opts = {}, &block)
    super name, opts, &block
  end

  def version
    "1.0.0"
  end

  def package_file
    "#{dir}/#{name}.#{version}.nupkg"
  end

  def package_spec
    "#{source_dir}/#{name}.nuspec"
  end

  def define_clean_task(configuration = default_configuration)
    super
    Rake::Task.define_task clean_task(configuration) do
      Rake::Task[package_clean_task].invoke
    end
  end

  def clean_package_task
    "#{namespace}:package:clean"
  end

  def define_clean_package_task
    Rake::Task.define_task clean_package_task do
      FileUtils.rm package_file rescue nil
    end
  end

  def package_task
    "#{namespace}:package"
  end

  def define_package_task
    dependencies = [dll, package_spec]

    Rake::Task.define_task package_task => dependencies do
      NuGet.pack package_spec, output_dir: File.dirname(package_file), package_analysis: false
    end

    Rake::FileTask.define_task package_file => dependencies do
      Rake::Task[package_task].invoke
    end
  end

  def define_tasks
    super
    define_clean_package_task
    define_package_task
  end
end

