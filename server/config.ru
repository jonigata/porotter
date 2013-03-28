require 'rubygems'
require 'bundler'
Bundler.require

Encoding.default_external = "UTF-8"
Encoding.default_internal = "UTF-8"

require './redis_mapper.rb'
RedisMapper::PlatformModel.set_redis(Redis.new)

require './models/user.rb'
require './models/users.rb'
require './models/post.rb'
require './models/timeline.rb'

URL_PREFIX='/foo'

require './web_server_helper'
require './app'
require './static'
require './account'
require './preferences'

map URL_PREFIX do
  map "/" do
    run Porotter.new
  end

  map '/static' do
    run Static.new
  end 

  map '/account' do
    run Account.new
  end

  map '/preferences' do
    run Preferences.new
  end
end




