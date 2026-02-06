module Peak::Rendering
  def self.included(klass) = klass.class_attribute(:to_partial_path)

  def render_in(view, &)
    view.render(partial: to_partial_path, object: self, &)
  end
end
