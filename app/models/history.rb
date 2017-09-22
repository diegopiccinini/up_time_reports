class History < ApplicationRecord
  belongs_to :job
  belongs_to :cron, optional: true

  @@verbose = false
  scope :by_job_name, -> (jobname) { includes(:job).where('jobs.name': jobname) }

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

  def self.log text:, level: 'info', status: 'message'
    self.create text: text, level: level, status: status, job: self.last.job, cron: self.last.cron
  end

  def self.start jobname, text=nil, cron: nil

    job = Job.find_or_create_by name: jobname
    text = "*** Starting #{jobname} ***" unless text
    self.create text: text, status: 'started', job: job, cron: cron
    output text, 2, 2

  end

  def self.finish text=nil
    text = "*** Finish the #{self.last.job.name} ***" unless text
    self.log text: text, status: 'finished'
    output text, 2, 2
  end

  def self.output text, lines_before=0, lines_after=0
    text = "\n" * lines_before + text + "\n" * lines_after
    puts text if self.verbose
  end

end
