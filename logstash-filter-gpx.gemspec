Gem::Specification.new do |s|

  s.name            = 'logstash-filter-gpx'
  s.version         = '0.0.1'
  s.licenses        = ['Apache License (2.0)']
  s.summary         = "This is a GPX filter used to parse and process this xml schema"
  s.description     = "This gem is a logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/plugin install gemname. This gem is not a stand-alone program"
  s.authors         = ["Pere Urbon-Bayes"]
  s.email           = 'pere.urbon@gmail.com'
  s.homepage        = "http://www.purbon.com"
  s.require_paths   = ["lib", "vendor"]

  # Files
  s.files = Dir["vendor/**/*", "lib/**/*","spec/**/*","*.gemspec","*.md","CONTRIBUTORS","Gemfile","LICENSE","NOTICE.TXT"]

  # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "filter" }

  s.add_runtime_dependency     "logstash-core-plugin-api", "~> 1.0"
  s.add_runtime_dependency     'nokogiri', '~> 1.6', '>= 1.6.7.2'
  s.add_development_dependency "logstash-devutils"
end

