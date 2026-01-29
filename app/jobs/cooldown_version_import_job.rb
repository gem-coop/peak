class CooldownVersionImportJob < ApplicationJob
  queue_as :default

  def perform
    CooldownVersion.import
  end
end
