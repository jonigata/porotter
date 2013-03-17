module WebServerHelper
  def static_url(entity)
    "#{URL_PREFIX}/static/#{entity.gsub(/^\//, '')}"
  end

  def local_url(action)
    action.gsub!(/^\//, '')
    "#{URL_PREFIX}#{here}/#{action}"
  end

  def parent_url(action)
    action.gsub!(/^\//, '')
    "#{URL_PREFIX}/#{action}"
  end

  def href(action)
    "href=\"#{local_url(action)}\""
  end

  def render_login_page(login_error, signup_error)
    erb :login, :locals => {
      :login_error => login_error,
      :signup_error => signup_error
    };
  end
end
