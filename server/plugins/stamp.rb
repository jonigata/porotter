# -*- coding: utf-8 -*-

module PlugIns
  module Stamp
    def self.display(service, post)
      content = post.store.content
      url = service.static_url("stamps/#{content}")
      "<img src=\"#{url}\">"
    end
  end
end
