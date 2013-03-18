class Post < RedisMapper::PlatformModel
  def self.create(user, content)
    self.new_instance do |post|
      post.store.author = user
      post.store.content = content
      post.store.created_at = post.store.updated_at = Time.now
      post.store.comments = Timeline.create
    end
  end

  def add_comment(author, content)
    self.store.comments.add_post(Post.create(author, content))
  end

  property  :author,        User
  property  :content,       String
  property  :created_at,    Time
  property  :updated_at,    Time
  property  :comments,      Timeline
end
