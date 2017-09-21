class History < ApplicationRecord
  belongs_to :job

  def self.write text, lines_before=0, lines_after=0, level: 'info'
    job=self.last.job
    self.create text: text, level: level, job: job
    output text, lines_before, lines_after
  end

  def self.verbose
    @@verbose || false
  end

  def self.verbose= value
    @@verbose=value
  end

  def self.start jobname, text=nil
    job = Job.find_or_create_by name: jobname
    text = "Starting the #{jobname} job" unless text
    self.create text: text, status: 'started', job: job
    output text, 2, 2
  end

  def self.finish text=nil
    job = self.last.job
    text = "Finish the #{job.name} job" unless text
    self.create text: text, status: 'finished', job: job
    output text, 2, 2
  end

  def self.output text, lines_before=0, lines_after=0
    text = "\n" * lines_before + text + "\n" * lines_after
    puts text if self.verbose
  end

end
