class CooldownVersionLineImportJob < ApplicationJob
  queue_as :default

  def perform(versions_byte, version_line)
    CooldownVersion.import_line(versions_byte, version_line)
  end
end
