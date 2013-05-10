# -*- coding: utf-8 -*-

module PlugIns
  module ArticleLog
    def self.display(settings, post)
      content = post.content
      "<span class=\"article-log-content\">#{content}</span>"
    end
  end
end
