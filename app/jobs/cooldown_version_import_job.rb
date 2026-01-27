class CooldownVersionImportJob < ApplicationJob
  queue_as :default

  def perform
    CooldownVersion.import(:perform_async)
  end
end
