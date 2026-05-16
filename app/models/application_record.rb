class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Define a one-to-one collaborator record relationship to an inner type with a lifecycle
  # tied to the outer type.
  #
  #   Outer.has_record :inner
  #   # `Outer.before_create` builds the inner type, so it's created alongside the outer type.
  #   # On `outer.destroy`, the inner type is marked as `dependent: :destroy`.
  #
  # Otherwise functional to a `has_one` relationship.
  def self.has_record(name, *, dependent: :destroy, **, &)
    has_one(name, *, dependent:, **, &).tap do
      before_create :"build_#{name}"
    end
  end

  def self.declare_immutable(**)
    after_find(:readonly!, **)
  end

  def mailer
    self.class::Mailer.with(model_name.singular.to_sym => self)
  end
end
