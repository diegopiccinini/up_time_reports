require File.join(Rails.root, 'lib', 'report_builder')
require File.join(Rails.root, 'lib', 'vpc_report_builder')
require File.join(Rails.root, 'lib', 'global_report_builder')

namespace :report do

  desc "To creates yesterday reports"
  task yesterday: :environment do
    History.verbose= true
    ReportGeneratorJob.perform_now(date: Date.yesterday)
    History.verbose= false
  end

  desc "To create a report by day"
  task :by_day, [:day] => :environment do |t, args|

    date=Date.parse args.day
    raise "I haven't the time machine to get a report for #{date}" if date>Date.today
    ReportGeneratorJob.perform_now(date: date)

  end

  desc "Create a daily reports between a period"
  task :by_day_in_period, [:from,:to] => :environment do |t, args|

    from=Date.parse args.from
    to=Date.parse args.to

    raise "I haven't the time machine to get a report for #{to}" if to>Date.today
    raise "#{from} date must be before #{to} date" if from>to

    History.verbose= true
    while from<to do
      ReportGeneratorJob.perform_now(date: from)
      from+=1
    end
    History.verbose= false

  end

  desc "Create a report by period and resolution params [date,period,resolution]"
  task :by_period_and_resolution, [:date,:period,:resolution] => :environment do |t, args|

    date=Date.parse args.date
    period=args.period
    resolution=args.resolution

    validation={ 'day' => ['hour'], 'week' => ['day'], 'month' => ['day','week'], 'year' => ['month'] }
    raise "I haven't the time machine to get a report for #{date}" if date>Date.today
    raise "#{period} is not a valid period" unless validation.keys.include?period
    raise "The resolution #{resolution} is invalid" unless validation[period].include?resolution

    History.verbose= true
    ReportGeneratorJob.perform_now(date: date, resolution: resolution, period: period)
    History.verbose= false

  end

  desc "execute the cron"
  task cron: :environment do

    puts "#{Time.now.to_s} There is not a cron to run" if Cron.to_run.count<1

    History.verbose= true
    Cron.to_run.each do |cron|
      cron.run!
    end
    History.verbose= false

  end

  desc "Execute one cron"
  task :run_one_cron, [:id] => :environment do |t, args|
    cron=Cron.find args.id
    History.verbose= true
    cron.run!
    History.verbose= false
  end

  desc "Build report"
  task :build, [:id] => :environment do |t, args|
    report=Report.find args.id
    builder=VpcReportBuilder.new report
    builder.build
  end

  desc "Rebuild Global Report"
  task :rebuild, [:id] => :environment do |t, args|
    global_report=GlobalReport.find args.id

    global_report.update( status: 'outages saved')
    global_report.reports.each { |r| r.update( status: 'outages saved' ) }
    job = Job.find_by name: 'Rebuild Reports'
    cron= Cron.find_by job: job
    History.verbose= true
    cron.run!
    History.verbose= false

  end

end
