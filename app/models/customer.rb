class Customer < ApplicationRecord

  acts_as_paranoid

  has_many :vpcs

end
