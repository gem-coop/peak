class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  alias_method :assign, :assign_attributes

  def self.has_one_built(name, ...)
    has_one(name, ...).tap do
      define_method("#{name}_scope") { association(name).scope }
      before_create :"build_#{name}"
    end
  end

  def self.declare_immutable(**)
    after_find(:readonly!, **)
  end

  def self.limit_reached?(limit)
    limit(limit).count >= limit
  end

  def self.const_get?(const)
    const_get(const) if const_defined?(const)
  end
  delegate :const_get?, to: :class

  def mailer
    self.class::Mailer.with(model_name.element.to_sym => self)
  end
end
