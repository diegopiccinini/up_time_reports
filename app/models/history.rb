class History < ApplicationRecord
  belongs_to :cron, optional: true
  belongs_to :history, optional: true

  @@verbose = false
  @@free= true

  def self.write text, lines_before=0, lines_after=0, level: 'info'
    if self.last and self.last.status!='finished'
      self.log text: text, level: level
    end
    output text, lines_before, lines_after
  end

  def self.verbose
    @@verbose
  end

  def self.verbose= value
    @@verbose=value
  end

  def self.free
    @@free
  end

  def self.free= value
    @@free=value
  end

  def self.log text:, level: 'info', status: 'message'
    self.create text: text, level: level, status: status, cron: self.last.cron, history: self.last.history
  end

  def self.start text, cron: nil
    if @@free
      h=self.create text: text, status: 'started', cron: cron
      output text, 2, 2
      h.update(history: h)
      @@free=false
    end
  end
  def self.finish text=nil
    text = "*** Finish ***" unless text
    if history=self.log( text: text, status: 'finished')
      output text, 2, 2
      @@free=true
    end
    history
  end

  def self.output text, lines_before=0, lines_after=0
    text = "\n" * lines_before + text + "\n" * lines_after
    puts text if self.verbose
  end

end
