# -*- coding: utf-8 -*-

module WebServerHelper
  def static_url(entity)
    "#{URL_PREFIX}/static/#{entity.gsub(/^\//, '')}"
  end

  def local_url(action)
    action.gsub!(/^\//, '')
    "#{env['SCRIPT_NAME']}/#{action}"
  end

  def parent_url(action)
    action.gsub!(/^\//, '')
    "#{URL_PREFIX}/#{action}"
  end

  def href(action)
    "href=\"#{local_url(action)}\""
  end

  def symbolize(s, candidates)
    # symbol leak対策のためinternしない
    candidates.each do |c|
      return c if c.to_s == s
    end
    return nil
  end

  def render_login_page(login_error, signup_error)
    erb :login, :locals => {
      :login_error => login_error,
      :signup_error => signup_error
    };
  end

  def ensure_login_user_except(namespaces)
    @user = User.attach_if_exist(session['user_id'])
    if !@user && !namespaces.member?(request.path_info.split('/')[1])
      redirect parent_url("/account/login"), 303
    end
  end

  def self.included(klass)
    klass.class_eval do
      configure :development do
        Dir.glob("#{File.dirname(__FILE__)}/plugins/*.rb") do |file|
          require file
        end

        register Sinatra::Reloader
        also_reload "#{File.dirname(__FILE__)}/*.rb"
        also_reload "#{File.dirname(__FILE__)}/models/*.rb"
        also_reload "#{File.dirname(__FILE__)}/plugins/*.rb"
      end

      enable :sessions
      set :session_secret, 'porotter secret'
      set :public_folder, "#{File.dirname(__FILE__)}/public"
    end
  end
end
