class History < ApplicationRecord

  def self.write text, level = 'info'
    self.create text: text, level: level
    puts text if self.verbose
  end
  def self.verbose
    @@verbose||=false
  end
  def self.verbose= value
    @@verbose=value
  end
end
