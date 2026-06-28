# Adapted to a single value version from https://github.com/rails/rails/pull/41622
ActiveRecord::Relation.prepend Module.new {
  def distinct_on_value
    @values.fetch(:distinct_on_value, nil)
  end

  def distinct_on_value=(value)
    assert_modifiable!
    @values[:distinct_on_value] = value
  end

  def distinct_on(column_name)
    spawn.distinct_on!(column_name)
  end

  def distinct_on!(column_name)
    self.distinct_on_value = column_name
    self
  end

  def build_arel(...)
    super.tap do
      _1.distinct_on(arel_column(distinct_on_value)) if distinct_on_value
    end
  end
} unless ActiveRecord::Relation.instance_methods.include?(:distinct_on)
