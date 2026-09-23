class DefaultEmptyGemSummary < ActiveRecord::Migration[8.1]
  def change
    change_column_default :namespace_gem_versions, :summary, ""
  end
end
