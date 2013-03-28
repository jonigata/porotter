# -*- coding: utf-8 -*-

class Static < Sinatra::Base
  get %r{/(.*)\.css} do |path|
    # TODO: symbol leak
    scss :"#{path}"
  end

  get %r{/(.*\.(js|css|png|gif))} do |path, ext|
    send_file File.join(settings.public_folder, path)
  end
end
