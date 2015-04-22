$:.push File.expand_path("../lib", __FILE__)
require "rubyserial/version"

Gem::Specification.new do |s|
  s.name        = "rubyserial-with-blocking"
  s.version     = RubySerial::VERSION
  s.summary     = "FFI Ruby library for RS-232 serial port communication"
  s.description = "FFI Ruby library for RS-232 serial port communication"
  s.homepage    = "https://github.com/hybridgroup/rubyserial"
  s.authors     = ["Adrian Zankich", "Theron Boerner", "Javier Cervantes", "Dirk Lüsebrink"]
  s.platform    = Gem::Platform::RUBY
  s.license     = 'Apache 2.0'

  s.files         = `git ls-files`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'ffi', '~> 1.9.3'

  s.add_development_dependency 'guard-rspec'
end
