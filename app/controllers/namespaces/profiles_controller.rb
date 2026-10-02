class Namespaces::ProfilesController < ApplicationController
  def show
    @namespace = Namespace.includes(:stable_index).named(params[:namespace])
    set_breadcrumb_trail @namespace

    @index = @namespace.stable_index
    @versions = @index.versions.distinct_on_gem.as_byline.latest_first.limit(20).sort_by { _1.gem.name }
  end
end
