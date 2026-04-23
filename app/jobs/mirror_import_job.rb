class MirrorImportJob < ApplicationJob
  queue_as :mirror

  def perform(*args)
    Namespace::Index::Mirror.find_each do |mirror|
      mirror.import
    end
  end
end
