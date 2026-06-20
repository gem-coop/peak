module ApplicationHelper
  class Page; attr_accessor :title; end
  def page = @page ||= Page.new

  def link_out_to(*, target: "_blank", **, &)
    link_to(*, target:, **, &)
  end

  def version_author(version)
    author = version.created_by
    return author.name unless author.is_a?(TrustedPublisher)

    safe_join([author.name, tag.i("· via #{author.provider_label}", style: "color: var(--secondary);")], " ")
  end
end
