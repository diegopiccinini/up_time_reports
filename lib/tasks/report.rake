namespace :report do

  desc "To creates yesterday reports"
  task yesterday: :environment do
    History.verbose= true
    ReportGeneratorJob.perform_now(Date.yesterday)
    History.verbose= false
  end

  desc "To create a report by day"
  task :by_day, [:day] => :environment do |t, args|

    date=Date.parse args.day
    raise "I haven't the time machine to get a report for #{date}" if date>Date.today
    ReportGeneratorJob.perform_now(date)

  end

  desc "Create a daily reports between a period"
  task :by_period, [:from,:to] => :environment do |t, args|

    from=Date.parse args.from
    to=Date.parse args.to

    raise "I haven't the time machine to get a report for #{to}" if to>Date.today
    raise "#{from} date must be before #{to} date" if from>to

    History.verbose= true
    while from<to do
      ReportGeneratorJob.perform_async(from)
      from+=1
    end
    History.verbose= false

  end

  desc "execute the cron"
  task cron: :environment do

    puts "There is not a cron to run" if Cron.to_run.count<1

    History.verbose= true
    Cron.to_run.each do |cron|
      cron.run!
    end
    History.verbose= false

  end

end
