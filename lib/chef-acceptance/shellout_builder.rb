module ChefAcceptance
  class ShelloutBuilder
    attr_reader :cwd, :recipe, :chef_config_file, :dna_json_file

    def initialize(options = {})
      @cwd = options.fetch(:cwd, Dir.pwd)
    end

    def with_recipe(recipe)
      @recipe = recipe
    end

    def with_chef_config_file(file)
      @chef_config_file = file
    end

    def with_dna_json_file(file)
      @dna_json_file = file
    end

    def build
      # check required elements and raise an error if they don't exist
      [:recipe, :chef_config_file, :dna_json_file].each do |required|
        if public_send(required).nil?
          fail "Required element #{required} is missing"
        end
      end

      [dna_json_file, chef_config_file].each do |file|
        fail "#{file} not found" unless File.exist? file
      end

      Mixlib::ShellOut.new(command, cwd: cwd, live_stream: $stdout)
    end

    private

    def command
      shellout = []
      shellout << 'chef-client -z'
      shellout << "-c #{File.expand_path(chef_config_file)}"
      shellout << '--force-formatter'
      shellout << "-j #{File.expand_path(dna_json_file)}"
      shellout << "-o #{recipe}"
      shellout.join(' ')
    end
  end
end
