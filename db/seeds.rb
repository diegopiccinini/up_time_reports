# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

GlobalSetting.set 'timezone', { value: 'UTC' }
GlobalSetting.set 'adjust_interval', { value: 180 }

Cron.delete_all
Job.delete_all

job=Job.find_or_create_by name: 'Initialize Daily VPC Reports'
source= %Q{ ReportGeneratorJob.perform_now(Date.yesterday, cron: cron) }
job.update( source: source)
Cron.find_or_create_by name: "#{job.name}, every day at 4:00 AM", hour: 4, job: job


job=Job.find_or_create_by name: 'Initialize Weekly VPC Reports'
source = %Q{ ReportGeneratorJob.perform_now(Date.parse('Monday').prev_week, period: 'week', resolution: 'day', cron: cron) }
job.update( source: source)
Cron.find_or_create_by name: "#{job.name}, every Monday at 6:00 AM", hour: 6, day_of_week: 1, job: job


job=Job.find_or_create_by name: 'Initialize Monthly VPC Reports with day Resolution'
source = %Q{ ReportGeneratorJob.perform_now(Date.today.prev_month.at_beginning_of_month, period: 'month', resolution: 'day', cron: cron) }
job.update( source: source)
Cron.find_or_create_by name: "#{job.name}, every 1st of month at 5:00 AM", hour: 5, day_of_month: 1, job: job


job=Job.find_or_create_by name: 'Initialize Monthly VPC Reports with week Resolution'
source = %Q{
    date=Date.today.prev_month.at_beginning_of_month
    date-= 1 until date.wday==1 #beginning on monday
    ReportGeneratorJob.perform_now(date, period: 'month', resolution: 'week', cron: cron)
}
job.update( source: source)
Cron.find_or_create_by name: "#{job.name}, every 2nd of month at 13:00 ", hour: 13, day_of_month: 2, job: job


job=Job.find_or_create_by name: 'VPC Update'
source = %Q{ VpcUpdateJob.perform_now(cron: cron) }
job.update( source: source)
cron=Cron.find_or_create_by name: "#{job.name} every day at 3:00 AM", hour: 3, job: job
cron.update(next_execution: Time.now)


job=Job.find_or_create_by name: 'Initialize Yearly VPC Reports with month Resolution'
source = %Q{
    date=Date.today.prev_year.at_beginning_of_year
    ReportGeneratorJob.perform_now(date, period: 'year', resolution: 'month', cron: cron)
}
job.update( source: source)
Cron.find_or_create_by name: "#{job.name}, every 2nd of Junuary at 3:00 AM", hour: 3, day_of_month: 2, month: 1, job: job


job=Job.find_or_create_by name: 'Build VPC Reports JSON Body'
source = %Q{ ReportBodyJob.perform_now(cron: cron) }
job.update( source: source)
Cron.find_or_create_by name: "#{job.name}, every day at 8:00 AM", hour: 8, job: job
Cron.find_or_create_by name: "#{job.name}, every day at 3:00 PM", hour: 15, job: job


if Rails.env.development?
  email='admin@example.com'
  AdminUser.create!(email: email, password: 'password', password_confirmation: 'password') unless AdminUser.find_by(email: email)
end
