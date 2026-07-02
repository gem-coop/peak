class Namespaces::ProfilesController < ApplicationController
  def show
    @namespace = Namespace.includes(:default_index).named(params[:namespace])
    set_breadcrumb_trail @namespace

    @index = @namespace.default_index
    @versions = @index.versions.distinct_on_gem_name.latest_first.as_byline.limit(20).load_async
  end
end
