class CooldownVersionLineImportJob < ApplicationJob
  queue_as :default

  def perform(versions_byte, version_line, from_scratch = false)
    CooldownVersion.import_line(versions_byte, version_line, from_scratch)
  end
end
