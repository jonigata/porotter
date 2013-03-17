class Post < RedisMapper::PlatformModel
  def self.create(user, content)
    self.new_instance do |post|
      post.store.author = user
      post.store.content = content
      post.store.created_at = post.store.updated_at = Time.now
    end
  end

  property  :author,        User
  property  :content,       String
  property  :created_at,    Time
  property  :updated_at,    Time
  property  :comments,      Timeline
end
