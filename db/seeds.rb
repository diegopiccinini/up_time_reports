# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

job=Job.find_or_create_by name: 'Initialize Daily Vpc Reports'
cron=Cron.find_or_create_by name: "#{job.name}, every day at 8:00 AM", hour: 8, job: job
cron.update(next_execution: Time.now)

job=Job.find_or_create_by name: 'Initialize Weekly Vpc Reports'
Cron.find_or_create_by name: "#{job.name}, every Monday at 9:00 AM", hour: 9, day_of_week: 1, job: job

job=Job.find_or_create_by name: 'Initialize Monthly Vpc Reports with day Resolution'
Cron.find_or_create_by name: "#{job.name}, every 1st of month at 5:00 AM", hour: 5, day_of_month: 1, job: job

job=Job.find_or_create_by name: 'Initialize Monthly Vpc Reports with week Resolution'
Cron.find_or_create_by name: "#{job.name}, every 1st of month at 4:00 AM", hour: 4, day_of_month: 1, job: job

job=Job.find_or_create_by name: 'Vpc Update'
Cron.find_or_create_by name: "#{job.name} every day at 7:00 AM", hour: 7, job: job


GlobalSetting.set 'adjust_interval', { value: 180 }
