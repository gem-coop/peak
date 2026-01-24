ActiveJob::Base.queue_adapter = :inline if Rails.env.development?
ActiveRecord::Base.logger = Logger.new STDOUT if ENV["VERBOSE"]

Oaken.seed :namespaces
Namespace::Index.find_each(&:compact)
