# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

# Set the environment
set :environment, Rails.env
set :output, "#{Rails.root}/log/cron.log"

# Process recurring payments daily at 6 AM
every 1.day, at: "6:00 am" do
  runner "RecurringPaymentJob.perform_later"
end

# Send payment reminders at 8 AM
every 1.day, at: "8:00 am" do
  runner "PaymentReminderJob.perform_later"
end

# Process overdue payments at 10 AM
every 1.day, at: "10:00 am" do
  runner "OverduePaymentJob.perform_later"
end

# Clean up old payment records monthly
every 1.month, at: "2:00 am" do
  runner "PaymentCleanupJob.perform_later"
end

# Generate monthly payment reports on the 1st of each month
every "0 9 1 * *" do
  runner "MonthlyPaymentReportJob.perform_later"
end

# Sync payment methods with Stripe weekly
every 1.week, at: "3:00 am" do
  runner "StripePaymentMethodSyncJob.perform_later"
end
