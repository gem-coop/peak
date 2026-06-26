module ApplicationHelper
  class Page; attr_accessor :title; end
  def page = @page ||= Page.new

  # Anchor only safe http(s) targets; unsafe stored URLs render as inert text.
  def link_out_to(name, url = name, target: "_blank", **options, &)
    return name unless Peak::Gem::Link.safe?(url)
    link_to(name, url, target:, **options, &)
  end
end
