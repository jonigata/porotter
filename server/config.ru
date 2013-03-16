require 'rubygems'
require 'bundler'
Bundler.require

Encoding.default_external = "UTF-8"
Encoding.default_internal = "UTF-8"

require './redis_mapper.rb'
require './models/user.rb'

URL_PREFIX='/foo'

require './app'
require './account'

map URL_PREFIX do
  map "/" do
    run Porotter.new
  end

  map '/account' do
    run Account.new
  end
end




