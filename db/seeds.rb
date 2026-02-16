ActiveRecord::Base.logger = Logger.new STDOUT if ENV["VERBOSE"]

ActiveJob::Base.with queue_adapter: :inline do
  Oaken.seed :data, :namespaces
end
