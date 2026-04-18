class CompactMirrorIndexesJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Namespace::Mirror.find_each do |mirror|
      mirror.namespace.external_index.compact
    end
  end
end
