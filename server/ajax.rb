# -*- coding: utf-8 -*-

class Ajax < Sinatra::Base
  helpers Sinatra::Jsonp
  helpers WebServerHelper
  helpers APIHelper

  before do
    ensure_login_user_except(['v'])
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
      params.enstructure(:post => [/[0-9]+/, Integer])
    end
    get_detail(r.post)
  end

  post '/m/newarticle' do
    post_new_article(params[:content])
  end

  post '/m/newcomment' do
    r = halt_on_exception do
      params.enstructure(:parent => [/[0-9]+/, Integer])
    end
    post_new_comment(r.parent, params[:content])
  end

  get '/m/favor' do
    halt_on_exception do
      r = params.enstructure(:target => [/[0-9]+/, Integer])
    end
    favor(r.target)
    "OK"
  end

end
