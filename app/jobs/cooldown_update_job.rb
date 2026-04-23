class CooldownUpdateJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Namespace::Index::Cooldown.find_each do |cooldown|
      cooldown.rebuild_infos
      cooldown.compact
    end
  end
end
