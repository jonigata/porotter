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
require './api_helper'
require './app'
require './ajax'
require './account'
require './preferences'
require './static'
require './webapi'

map URL_PREFIX do
  map "/" do
    run Porotter.new
  end

  map "/ajax" do
    run Ajax.new
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

  map '/api' do
    run WebAPI.new
  end 
end
