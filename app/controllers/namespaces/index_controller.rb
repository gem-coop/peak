class Namespaces::IndexController < ApplicationController
  before_action :set_index

  def index
    render plain: @index.load_versions_contents if stale? @index
  end

  def show
    if stale? info = @index.gems.named(params[:id]).info
      render plain: info.contents
    end
  end

  private
    def set_index
      @index = Namespace.named(params[:namespace]).external_index
    end
end
