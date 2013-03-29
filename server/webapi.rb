# -*- coding: utf-8 -*-

class WebAPI < Sinatra::Base
  helpers Sinatra::Jsonp
  helpers WebServerHelper
  helpers APIHelper

  configure do
    api_key = ''
    filename = "#{File.dirname(__FILE__)}/API_KEY"

    if !File.exists?(filename)
      open(filename, "w") do |file|
        api_key = Digest::MD5.new.update("porotter" + Misc.new_salt)
        file.write(api_key)
      end
    else
      open(filename) do |file|
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

end
