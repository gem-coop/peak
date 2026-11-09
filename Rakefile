# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "config/application"

task "db:schema:dump" do
  Rails.application.eager_load!

  ignored = ApplicationRecord.lease_connection.tables - ActiveRecord::Base.descendants.map(&:table_name).compact_blank
  ActiveRecord::SchemaDumper.ignore_tables = ignored
end

Rails.application.load_tasks
