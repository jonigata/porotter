# -*- coding: utf-8 -*-

module PlugIns
  module Tweet
    def self.display(settings, post)
      content = post.store.content
      if content == ''
        "<span class='deleted'>この投稿は削除されています</span>"
      else
        Sanitize.clean(content).gsub(URI.regexp) do |uri|
          "<a class='external-link' href='#{uri}' target='_blank'>#{uri}</a>"
        end
      end
    end
  end
end
