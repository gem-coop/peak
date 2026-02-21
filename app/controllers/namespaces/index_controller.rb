class Namespaces::IndexController < ApplicationController
  before_action :set_routed_index

  def index
    render plain: @index.versions_contents if stale? @index
  end

  def show
    if stale? info = @index.gems.named(params[:id]).info
      render plain: info.contents
    end
  end
end
