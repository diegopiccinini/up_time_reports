class History < ApplicationRecord

  def self.write text, lines_before=0, lines_after=0, level: 'info'
    self.create text: text, level: level
    text = "\n" * lines_before + text + "\n" * lines_after
    puts text if self.verbose
  end

  def self.verbose
    @@verbose || false
  end

  def self.verbose= value
    @@verbose=value
  end
end
