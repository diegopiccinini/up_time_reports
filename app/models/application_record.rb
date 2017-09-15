class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  private

  def validate_inclusion key, collection
    value=send(key)
    errors.add(key, "#{value} is not a valid #{key.to_s}") unless collection.include?(value)
  end

end
