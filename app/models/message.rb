class Message
  include RedisModel
  include ActiveModel::Conversion
  extend  ActiveModel::Naming
  include ActiveModel::Validations

  redis_attrs :id, :channel_id, :user_id, :message
  redis_idx('user_id', 'TAG', 'channel_id', 'TAG', 'message', 'TEXT') rescue nil

  validates_presence_of :channel_id, :user_id, :message

  def self.redisearch
    @@redisearch ||= RediSearch.new("idx:#{name.downcase.pluralize}")
  end
end
