class Namespaces::Gems::ProfilesController < ApplicationController
  before_action :set_index

  def show
    @gem = @index.gems.named(params[:id])
    set_breadcrumb_trail @index.namespace, @gem

    @latest = @gem.versions.pure.latest_by_ref
    @versions = @gem.versions.pure.as_byline.latest_first.limit(20)
  end

  private
    def set_index
      @index = Namespace.named(params[:namespace]).stable_index
    end
end
