class History < ApplicationRecord
  belongs_to :cron, optional: true
  belongs_to :history, optional: true

  @@verbose = false

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
    if self.current
      self.current[:free]
    else
      self.reset
    end
  end

  def self.reset
    GlobalSetting.set 'current_history' , { free: true }
  end

  def self.current
    GlobalSetting.get 'current_history'
  end

  def self.log text:, level: 'info', status: 'message'
    current= self.current
    data = { text: text, level: level, status: status, history_id: current[:started_history_id] }
    data[:cron_id] = current[:cron_id] if current[:cron_id]
    self.create data
  end

  def self.start text, cron: nil
    history=false
    if self.free
      history=self.create text: text, status: 'started', cron: cron
      data =  { free: false, started_history_id: history.id }
      data[:cron_id] = cron.id if cron
      GlobalSetting.set 'current_history', data
      output text, 2, 2
    end
    history
  end

  def self.finish text=nil
    text = "*** Finish ***" unless text
    if history=self.log( text: text, status: 'finished')
      output text, 2, 2
      current = self.current
      current[:free]=true
      current[:end_history_id]=history.id
      GlobalSetting.set 'current_history', current
    end
    history
  end

  def self.output text, lines_before=0, lines_after=0
    text = "\n" * lines_before + text + "\n" * lines_after
    puts text if self.verbose
  end

end
