class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def self.declare_immutable(**)
    after_find(:readonly!, **)
  end

  def mailer
    self.class::Mailer.with(model_name.singular.to_sym => self)
  end

  def read_unloaded_attribute(key)
    read_attribute(key) || write_attribute(key, self.class.where(id:).pick(key))
  end
end
