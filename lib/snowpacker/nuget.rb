module NuGet
  class << self
	  Location = if OS.windows?
                 "#{Dir.home}\\bin\\NuGet.exe"
               else
                 "#{Dir.home}/NuGet.exe"
               end
    Config = "#{Dir.home}/.config/NuGet/NuGet.config"
    AddIn = ["XamarinStudio-4.0", "MonoDevelop-3.0"].map { |ide| Dir.glob("#{Dir.home}/Library/Application Support/#{ide}/LocalInstall/Addins/MonoDevelop.PackageManagement.0.*").first }.compact.detect { |dir| Dir.exists? dir }

	  def pack(nuspec, opts = {})
      if OS.windows?
        nuspec = generate_windows_nuspec nuspec
      end

      command_opts = opts.map do |opt, val|
        case opt
        when :package_analysis
          "-NoPackageAnalysis" if val == false
        when :output_dir
          "-OutputDirectory '#{val}'"
        end
      end.compact.join " "

      Mono.run "'#{Location}' pack #{command_opts} #{nuspec}"
	  end
    
    def generate_windows_nuspec(nuspec)
      xml = REXML::Document.new File.new(nuspec)
      xml.elements.each "package/files/file" do |file|
        ["src", "target"].each do |attr|
          file.attributes[attr].gsub! "/", "\\"
        end
      end
      windows_nuspec = nuspec.gsub ".nuspec", "-windows.nuspec"
      File.open windows_nuspec, "w" do |file|
        xml.write file
      end
      windows_nuspec
    end

    def package_sources
      REXML::Document.new(File.new(Config)).elements.enum_for(:each, "configuration/packageSources/add").map do |source|
        source.attributes["value"]
      end
    end

    def local_package_dir(package)
      package_sources.map do |source|
        "#{source}/#{package[:id]}"
      end.detect do |source|
        File.directory? source
      end
    end

    def package_str(package)
      "#{package[:id]} (#{package[:version]})"
    end

    def package_dir(package)
      "#{package[:id]}.#{package[:version]}"
    end

    def install_package(package, directory, root)
      install_packages [package], directory, root
    end

    def install_packages(packages, directory, root)
      puts "Installing #{packages.map { |p| package_str p }.join ", "} into #{directory}"

      packages.each do |package|
        FileUtils.rm_rf "#{directory}/#{package_dir package}"
      end

      install_packages = packages.map do |package|
        %|packageManager.InstallPackage("#{package[:id]}", SemanticVersion.Parse("#{package[:version]}"));|
      end

      package_repositories = package_sources.map do |source|
        %|PackageRepositoryFactory.Default.CreateRepository("#{source}")|
      end

# public class NullProjectSystem : PhysicalFileSystem, IProjectSystem
# {
#   bool IsBindingRedirectSupported { get { return true; } }
# 
#   public void AddFrameworkReference(string name)
#   {
#   }
# 
#   public void AddReference(string referencePath, Stream stream)
#   {
#   }
# 
#   FrameworkName TargetFramework { get { return null; } }
# 
#   bool IsSupportedFile(string path) { return true; }
#   bool ReferenceExists(string name) { return false; }
#   void RemoveReference(string name) { }
#   string ResolvePath(string path)
#   {
#     return path;
#   }
# }
# var project = new NullProjectSystem();
# var projectManager = new ProjectManager(packageManager.SourceRepository, packageManager.PathResolver, project, packageManager.LocalRepository);

      csharp = <<END
using NuGet;

var repo = new AggregateRepository(new [] { #{package_repositories.join ", "} });
var packageManager = new PackageManager(repo, "#{directory}");
#{install_packages.join "\n"}
END

      system %[echo '#{csharp}' | csharp "-lib:#{AddIn}" -reference:NuGet.Core.dll]

      packages.each do |package|
        # Update directory timestamp since we changed its contents,
        # so it is newer than the files that went into the package.
        # Otherwise, package installation task will be triggered unnecessarily on subsequent runs
        update_dir_timestamp "#{directory}/#{package_dir package}"
        update_dir_timestamp directory
        FileUtils.cp_r Dir.glob("#{directory}/#{package_dir package}/content/*"), "#{root}/."
      end
    end

    private

    def update_dir_timestamp(dir)
      system "touch '#{dir}'" if File.directory? dir
    end
  end
end

