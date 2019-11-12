class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable , :omniauthable, omniauth_providers: [:central_auth]


  def to_s
    email
  end

  before_create do
    self.expired_at = DateTime.now + 6.months
  end

  def self.from_omniauth(auth)
    if ENV['CUSTOM_DOMAIN_FILTER'].split.include?(auth[:info][:email].split('@').last)
      user = find_or_create_by email: auth[:info][:email]

      user.provider = auth[:provider]
      user.uid = auth[:uid]
      user.name = auth[:info][:name]
      user.first_name = auth[:info][:first_name]
      user.last_name = auth[:info][:last_name]
      user.save(validate: false)
      user
    end

  end

  def expired?
    self.expired_at < DateTime.now
  end
end
