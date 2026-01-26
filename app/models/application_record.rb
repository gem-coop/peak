class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def read_unloaded_attribute(key)
    read_attribute(key) || write_attribute(key, self.class.where(id:).pick(key))
  end
end
