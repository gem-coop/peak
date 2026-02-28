module ApplicationHelper
  class Page; attr_accessor :title; end
  def page = @page ||= Page.new

  def link_out_to(*, target: "_blank", **, &)
    link_to(*, target:, **, &)
  end
end
