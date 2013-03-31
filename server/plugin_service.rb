class PluginService
  def initialize(settings)
    @settings = settings
  end

  def static_url(entity)
    "#{URL_PREFIX}/static/#{entity.gsub(/^\//, '')}"
  end
end
