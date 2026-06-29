class Namespaces::ProfilesController < ApplicationController
  before_action :set_index

  def show
    @versions = @index.versions.distinct_on_gem_name.latest_first.as_byline.load_async
  end

  private
    def set_index
      @index = Namespace.named(params[:namespace]).default_index
    end
end
