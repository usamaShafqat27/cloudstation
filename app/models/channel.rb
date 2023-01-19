class Channel
  include RedisModel
  include ActiveModel::Conversion
  extend  ActiveModel::Naming
  include ActiveModel::Validations

  redis_attrs :name, :updated_at
  primary_id :name
  has_stream true
  validates_presence_of :name, :updated_at

  def last_message
    Message.find($redis.xrevrange("channel:stream:#{id}", count: 1).first.first) rescue nil
  end
end
