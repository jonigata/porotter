# -*- coding: utf-8 -*-

class Ajax < Sinatra::Base
  helpers Sinatra::Jsonp
  helpers WebServerHelper
  helpers APIHelper

  before do
    ensure_login_user_except(['v'])
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
    post_new_article(params[:content])
  end

  post '/m/newcomment' do
    r = ensure_params(
      :parent => [/[0-9]+/, Integer])
    post_new_comment(r.parent, params[:content])
  end

  post '/m/favor' do
    r = ensure_params(
      :target => [/[0-9]+/, Integer])
    favor(r.target)
    "OK"
  end

end
