source 'http://rubygems.org'

gem 'sinatra'
gem 'sinatra-activerecord'
gem 'rack-contrib'

# Because of a bug in rack-protection (https://github.com/rkh/rack-protection/commit/a91810fa) that affects
# cors-requests we'll need to get rack-protection from github
# This can safely be changed to the official rubygems version '> 1.2.0' whenever it is released
gem 'rack-protection', :git => 'git://github.com/rkh/rack-protection.git'

gem 'activerecord', :require => 'active_record'
gem 'activesupport'
gem 'pg'
gem 'omniauth', '~> 1.0.2'
gem 'omniauth-twitter', :git => 'git://github.com/arunagw/omniauth-twitter.git'
gem 'omniauth-facebook', '~> 1.2.0'
gem 'omniauth-contrib', '~> 1.0.0', :git => 'git://github.com/intridea/omniauth-contrib.git'
gem 'omniauth-oauth', '~> 1.0.0', :git => 'git://github.com/intridea/omniauth-oauth.git'
gem 'omniauth-origo', '~> 1.0.0.rc3', :git => 'git://github.com/bengler/omniauth-origo.git'
gem 'omniauth-vanilla', :git => 'git@github.com:bengler/omniauth-vanilla.git'
gem 'omniauth-google-oauth2', '~> 0.1.10'
gem 'pebblebed'
gem 'pebbles-cors', :git => 'git@github.com:bengler/pebbles-cors.git'
gem 'yajl-ruby', :require => 'yajl'
gem 'dalli', '~> 2.1.0'
gem 'thor'
gem 'unicorn', '~> 4.1.1'
gem 'petroglyph'
gem 'rake'
gem 'rack', '~> 1.4', :git => 'git://github.com/rack/rack.git'
gem 'queryparams'
gem 'bengler_test_helper', :git => 'git://github.com/bengler/bengler_test_helper.git', :require => false
gem 'simpleidn', '~> 0.0.4'
gem 'rest-client', :require => false  # Used by origo.thor
gem 'ar-tsvectors', '~> 0.0.1', :require => 'activerecord_tsvectors'
gem 'curb', '>= 0.7.14'
gem 'airbrake', '~> 3.1.4', :require => false

group :development, :test do
  gem 'simplecov'
  gem 'rspec', '~> 2.8'
  gem 'webmock'
  gem 'vcr'
  gem 'timecop', '~> 0.3.5'
  gem 'rack-test'
end
