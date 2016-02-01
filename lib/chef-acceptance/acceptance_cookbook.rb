module ChefAcceptance
  class AcceptanceCookbook
    CORE_ACCEPTANCE_RECIPES = %w{provision verify destroy}.freeze

    ACCEPTANCE_COOKBOOK_NAME = "acceptance-cookbook".freeze

    attr_reader :root_dir

    def initialize(base_path)
      @root_dir = File.join(base_path, ACCEPTANCE_COOKBOOK_NAME)
    end

    def generate
      create_cookbook_directories
      create_recipe_files
      create_metadata_file
      create_gitignore_file
    end

    private

    def create_cookbook_directories
      FileUtils.mkpath recipes_dir
    end

    def create_recipe_files
      CORE_ACCEPTANCE_RECIPES.each do |recipe|
        File.write(File.join(recipes_dir, "#{recipe}.rb"), recipe_file_template(recipe))
      end
    end

    def create_metadata_file
      File.write(File.join(root_dir, "metadata.rb"), metadata_file_template)
    end

    def create_gitignore_file
      File.write(File.join(root_dir, ".gitignore"), gitignore_file_template)
    end

    def recipes_dir
      File.join(root_dir, "recipes")
    end

    def recipe_file_template(recipe_name)
      <<-EOS
log "Running '#{recipe_name}' recipe from the acceptance-cookbook in directory '#\{node['chef-acceptance']['suite-dir']\}'"
      EOS
    end

    def metadata_file_template
      <<-EOS
name '#{ACCEPTANCE_COOKBOOK_NAME}'
      EOS
    end

    def gitignore_file_template
      <<-EOS
nodes/
tmp/
      EOS
    end
  end
end
