# -*- coding: utf-8 -*-

class WebAPI < Sinatra::Base
  helpers Sinatra::Jsonp
  helpers WebServerHelper
  helpers APIHelper

  configure do
    api_key = ''

    if !File.exists?('./API_KEY')
      open("./API_KEY", "w") do |file|
        api_key = Digest::MD5.new.update("porotter" + Misc.new_salt)
        file.write(api_key)
      end
    else
      open("./API_KEY") do |file|
        api_key = file.read
        puts "API_KEY = #{api_key}"
      end
    end

    set :api_key, api_key
  end

  before do
    r = halt_on_exception do
      params.enstructure(
        :api_key => [/[0-9a-f]+/, String],
        :username => [/[-_a-zA-Z0-9]+/, String],
        :password => [/[-_a-zA-Z0-9]+/, String])
    end
    r.api_key == settings.api_key or halt 403
    @user = User.auth(r.username, r.password)
  end

  get '/v/timeline' do
    r = halt_on_exception do
      params.enstructure(
        :timeline => [/[0-9]+/, Integer],
        :level => [/[0-9]+/, Integer])
    end
    get_timeline(r.timeline, r.level)
  end

  get '/v/detail' do
    r = halt_on_exception do
      params.enstructure(
        :post => [/[0-9]+/, Integer])
    end
    get_detail(r.post)
  end

  post '/m/newarticle' do
    post_new_article(params[:content])
  end

  post '/m/newcomment' do
    r = halt_on_exception do
      params.enstructure(
        :parent => [/[0-9]+/, Integer])
    end
    post_new_comment(r.parent, params[:content])
  end

  post '/m/favor' do
    halt_on_exception do
      r = params.enstructure(
        :api_key => [/[0-9a-f]+/, String],
        :username => [/[-_a-zA-Z0-9]+/, String],
        :password => [/[-_a-zA-Z0-9]+/, String],
        :target => [/[0-9]+/, Integer])
    end
    auth_api(r)
    favor(r.target)
    "OK"
  end
end
