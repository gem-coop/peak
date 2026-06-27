module ApplicationHelper
  class Page; attr_accessor :title; end
  def page = @page ||= Page.new
end
