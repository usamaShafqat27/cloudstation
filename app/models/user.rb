class User
  include ActiveModel::Validations
  include ActiveModel::SecurePassword
  include ActiveModel::Model

  include RedisModel

  redis_attrs :firstname, :lastname, :city, :country, :username, :password_digest
  primary_id :username
  has_secure_password

  validates_presence_of :firstname, :lastname, :username, :city, :country, :password_digest
end
