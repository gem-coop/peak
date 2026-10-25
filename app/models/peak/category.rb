class Peak::Category < Data.define(:name, :permalink, :description, :projects)
  Group = Data.define :name, :categories

  all = YAML.safe_load(Rails.root.join("config/storage/categories.yml").read).map(&:deep_symbolize_keys)
  all.map! { Group[_1[:name], _1[:categories].map { self[**it] }] }
  Group.define_singleton_method(:all) { all }
  Group.define_singleton_method(:lettered) { all.group_by { it.name.first.upcase } }
  Group.define_singleton_method(:letters) { lettered.keys }

  def self.find(id) = @index.fetch(id) { raise ActiveRecord::RecordNotFound }
  def self.projects = @index.values.flat_map(&:projects)
  @index = Group.all.flat_map(&:categories).index_by(&:permalink)
end
