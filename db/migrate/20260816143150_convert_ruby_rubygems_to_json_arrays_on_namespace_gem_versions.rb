class ConvertRubyRubygemsToJsonArraysOnNamespaceGemVersions < ActiveRecord::Migration[8.1]
  def change
    safety_assured {
      rename_column :namespace_gem_versions, :ruby, :ruby_old
      add_column :namespace_gem_versions, :ruby, :json, default: [], null: false

      rename_column :namespace_gem_versions, :rubygems, :rubygems_old
      add_column :namespace_gem_versions, :rubygems, :json, default: [], null: false

      up_only do
        Namespace::Gem::Version.find_each do |v|
          v.update! ruby: v.ruby_old.to_s.split(", "), rubygems: v.rubygems_old.to_s.split(", ")
        end
      end
    }
  end
end
