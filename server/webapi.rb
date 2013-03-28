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
    r = ensure_params(
      :api_key => [/[0-9a-f]+/, String],
      :username => [/[-_a-zA-Z0-9]+/, String],
      :password => [/[-_a-zA-Z0-9]+/, String])
    r.api_key == settings.api_key or halt 403
    @user = User.auth(r.username, r.password)

    content_type 'text'
  end

  get '/v/timeline' do
    r = ensure_params(
      :timeline => [/[0-9]+/, Integer],
      :newest_version => [/[0-9]+/, Integer],
      :count => [/[0-9]+/, Integer])
    get_timeline(r.timeline, r.newest_version, r.count)
  end

  get '/v/detail' do
    r = ensure_params(
        :post => [/[0-9]+/, Integer])
    get_detail(r.post)
  end

  post '/m/newarticle' do
    post_new_article(params[:content]).to_s
  end

  post '/m/newcomment' do
    r = ensure_params(
        :parent => [/[0-9]+/, Integer])
    post_new_comment(r.parent, params[:content]).to_s
  end

  post '/m/favor' do
    r = ensure_params(
        :target => [/[0-9]+/, Integer])
    favor(r.target)
    "OK"
  end
end
