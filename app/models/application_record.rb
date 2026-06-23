class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  alias_method :assign, :assign_attributes

  def self.has_one_built(name, ...)
    has_one(name, ...).tap do
      before_create :"build_#{name}"
    end
  end

  def self.declare_immutable(**)
    after_find(:readonly!, **)
  end

  def mailer
    self.class::Mailer.with(model_name.element.to_sym => self)
  end
end
