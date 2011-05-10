require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "rengine"
    gem.summary = %Q{one-line summary of your gem}
    gem.description = %Q{longer description of your gem}
    gem.email = "david@cloudwow.com"
    gem.homepage = "http://github.com/cloudwow/rengine"
    gem.authors = ["cloudwow"]
    gem.add_development_dependency "thoughtbot-shoulda"
    gem.require_paths=['lib']
    gem.add_dependency( "oauth")
    gem.add_dependency( "portablecontacts")
    gem.add_dependency( "nanikore")
    gem.add_dependency( "xml-simple")
    gem.add_dependency( "erubis")
    gem.add_dependency( "not_relational")
    gem.add_dependency( "image_science")

    
    # gem is a Gem::Specification... see
    # http://www.rubygems.org/read/chapter/20 for additional settings

    gem.executables = ['rengine_work','rengine_work_control']
    gem.files = [
                 "LICENSE",
                 "README.rdoc",
                 "Rakefile",
                 "VERSION",
                 "lib/rengine.rb",
                 "lib/rengine/uri_util.rb",
                 "lib/rengine/static_file_manager.rb",
                 "lib/rengine/error.rb",
                 "lib/rengine/user.rb",
                 "lib/rengine/blurb.rb",
                 "lib/rengine/blurb_map.rb",
                 "lib/rengine/blurb_wording.rb",
                 "lib/rengine/page_cache_item.rb",
                 "lib/rengine/weblab.rb",
                 "lib/rengine/language.rb",
                 "lib/rengine/render_base.rb",
                 "lib/rengine/weblab_base.rb",
                 "lib/rengine/memory_blurb_map.rb",
                 "lib/rengine/renderer.rb",
                 "lib/rengine/work_result.rb",
                 "lib/rengine/work_request.rb",
                 "lib/rengine/acts_as_log_writer.rb",
                 "lib/rengine/offline_worker.rb",
                 "lib/rengine/yahoo_oauth.rb",
                 "lib/rengine/facebook_oauth.rb",
                 "lib/rengine/google_oauth.rb",
                 "lib/rengine/yahoo_oauth.rb",
                 "lib/rengine/acts_as_rengine_controller.rb",
                 "lib/rengine/acts_as_account_controller.rb",
                 "lib/rengine/acts_as_weblab_controller.rb",
                 "lib/rengine/views/translation_tool.html.erb",
                 "lib/rengine/translation_tool.rb",
                 "lib/rengine/http_accept_language.rb",
                 "lib/rengine/views/single_translation_tool.html.erb",
                 "lib/rengine/extensions/string.rb",
                 "lib/rengine/bin/rengine_work",
                 "lib/rengine/bin/rengine_work_control",
                 "lib/rengine/imager.rb"
                ]


    # gem.files=[".document",
    #  ".gitignore",
    #  "LICENSE",
    #  "README.rdoc",
    #  "Rakefile",
    #  "VERSION",
    #  "lib/rengine.rb",
    #  "test/rengine_test.rb",
    #  "test/test_helper.rb",
    #  "lib/rengine/blurb_map.rb",
    #  "lib/rengine/page_cache_item.rb",
    #  "lib/rengine/weblab.rb",
    #  "lib/rengine/language.rb",
    #  "lib/rengine/render_base.rb",
    #  "lib/rengine/weblab_base.rb",
    #  "lib/rengine/memory_blurb_map.rb",
    #  "lib/rengine/renderer.rb"]
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "rengine #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
task :tags  do
  files = FileList['**/*.rb'].exclude("vendor")

  puts "Making Emacs TAGS file"

  puts "ctags -f #{files}"
  sh "ctags -e #{files}", :verbose => false

end
