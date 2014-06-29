Gem::Specification.new do |s|
  s.name        = 'boshify'
  s.version     = '0.1.0'
  s.licenses    = ['Apache']
  s.summary     = 'Generates BOSH releases'
  s.description = s.summary
  s.authors     = ['Andrew Crump']
  s.email       = 'andrew@cloudcredo.com'
  s.files       = Dir['lib/**/**.rb']
  s.homepage    = 'https://github.com/cloudcredo/boshify'
  s.add_runtime_dependency 'httparty', '~> 0.13.1'
  s.executables << 'boshify'
end
