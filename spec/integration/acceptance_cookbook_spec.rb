require "spec_helper"
require "chef-acceptance/cli"

context "generate command" do
  let(:options)  { [ "generate", "trivial" ] }

  it "generates a cookbook" do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        ChefAcceptance::Cli.start(options)
        cookbook_directory = File.join(dir, "trivial/.acceptance/acceptance-cookbook")

        %w{metadata.rb .gitignore}.each do |file|
          path = File.join(cookbook_directory, file)
          expect(File.exist?(path)).to be true
        end

        ["provision", "verify", "destroy"].each do |recipe|
          path = File.join(cookbook_directory, "recipes", "#{recipe}.rb")
          expect(File.exist?(path)).to be true
        end
      end
    end
  end
end
