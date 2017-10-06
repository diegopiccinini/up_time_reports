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
      history.running_cron
      data =  { free: false, started_history_id: history.id }
      data[:cron_id] = cron.id if cron
      GlobalSetting.set 'current_history', data
      output text, 2, 2
    end
    history
  end

  def self.finish text=nil, cron_status: 'ok'
    text = "*** Finish ***" unless text
    if history=self.log( text: text, status: 'finished')
      output text, 2, 2
      current = self.current
      current[:free]=true
      current[:end_history_id]=history.id
      history.finish_cron cron_status: cron_status
      GlobalSetting.set 'current_history', current
    end
    history
  end

  def self.output text, lines_before=0, lines_after=0
    text = "\n" * lines_before + text + "\n" * lines_after
    puts text if self.verbose
  end

  def self.execution cron: nil
    begin

      yield

      cron_status='ok'

    rescue => e
      cron_status='error'
      message="Error: #{e.message}\n\nBacktrace: #{e.backtrace.join("\n")}"
      cron.update(message: message) if cron
      History.write message, level: cron_status
    end

    History.finish cron_status: cron_status
  end

  def finish_cron cron_status: 'ok'
    cron.finish! status: cron_status if cron
  end

  def running_cron
    cron.update(status: 'running') if cron
  end

end
