class UnityManagedProject < Project
  def initialize(name, &block)
    super name, &block
  end

  def assets
    "#{dir}/Assets"
  end

  def plugins
    "#{assets}/Plugins"
  end

  def package_config
    "#{dir}/packages.config"
  end

  def dll_dir(configuration = default_configuration)
    "#{dir}/Temp/bin/#{configuration}"
  end

  def project_dir
    dir
  end
end

