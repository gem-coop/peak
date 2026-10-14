class Namespace::Gem::Version::Destroyer < ActiveRecord::AssociatedObject
  def destroy
    if destroyable?
      version.destroy!
      version.index.compact_later
    end
  end

  def destroyable?
    version.published_at.within?(48.hours) || version.referrants.zero?
  end
end
