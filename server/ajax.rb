# -*- coding: utf-8 -*-

class Ajax < Sinatra::Base
  helpers Sinatra::Jsonp
  helpers WebServerHelper
  helpers APIHelper

  before do
    ensure_login_user_except(['v'])
  end

end
