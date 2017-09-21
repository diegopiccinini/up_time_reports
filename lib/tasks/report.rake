namespace :report do

  desc "To creates yesterday reports"
  task yesterday: :environment do
    ReportSaveDailyDataJob.perform_now(Date.yesterday)
  end

  desc "To create a report by day"
  task :by_day, [:day] => :environment do |t, args|

    date=Date.parse args.day
    raise "I haven't the time machine to get a report for #{date}" if date>Date.today
    ReportSaveDailyDataJob.perform_now(date)

  end

  desc "Create a daily reports between a period"
  task :by_period, [:from,:to] => :environment do |t, args|

    from=Date.parse args.from
    to=Date.parse args.to

    raise "I haven't the time machine to get a report for #{to}" if to>Date.today
    raise "#{from} date must be before #{to} date" if from>to

    while from<to do
      ReportSaveDailyDataJob.perform_async(from)
      from+=1
    end

  end

  desc "TODO"
  task by_year: :environment do
  end

end
