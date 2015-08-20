$:.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'aws_configurer'

Gem::Specification.new do |spec|
  spec.name             = 'aws_configurer'
  spec.version          = AwsConfigurer::VERSION
  spec.summary          = 'AWS Configurer'
  spec.description      = 'Configure AWS accounts for CloudTrail, Root Account Usage Monitor.'
  spec.author           = 'Rianol Jou'
  spec.email            = 'rianol.jou@gmail.com'
  spec.homepage         = 'https://github.com/KKBOX/aws_configurer'
  spec.license          = 'MIT'

  spec.files            = Dir['bin/*', 'lib/**/*.rb', 'LICENSE', 'README.md']
  spec.executables      = Dir['bin/*'].map { |f| File.basename(f) }
  spec.require_paths    = ['lib']

  spec.add_dependency 'aws-sdk', '~> 2.0'
end
