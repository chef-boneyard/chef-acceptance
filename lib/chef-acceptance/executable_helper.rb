module ChefAcceptance
  module ExecutableHelper
    module_function

    def executable_installed?(executable)
      exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each do |ext|
          exe = File.join(path, "#{executable}#{ext}")
          return exe if File.executable?(exe) && !File.directory?(exe)
        end
      end
      false
    end
  end
end
