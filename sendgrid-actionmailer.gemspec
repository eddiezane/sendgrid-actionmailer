# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sendgrid-actionmailer/version'

Gem::Specification.new do |spec|
  spec.name          = 'sendgrid-actionmailer'
  spec.version       = SendGridActionMailer::VERSION
  spec.authors       = ['Eddie Zaneski']
  spec.email         = ['community@sendgrid.com']
  spec.summary       = %q{SendGrid support for ActionMailer.}
  spec.description   = %q{Use ActionMailer with SendGrid's Web API.}
  spec.homepage      = 'https://github.com/eddiezane/sendgrid-actionmailer'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'sendgrid-ruby'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake'
end
