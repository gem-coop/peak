module Peak::Rendering
  def self.included(klass) = klass.include(ActiveModel::API)

  def render_in(view, &)
    view.render(partial: to_partial_path, object: self, &)
  end
end
