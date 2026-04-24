class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def self.declare_immutable(**)
    after_find(:readonly!, **)
  end

  def mailer
    self.class::Mailer.with(model_name.singular.to_sym => self)
  end
end
