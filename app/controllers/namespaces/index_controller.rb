class Namespaces::IndexController < ApplicationController
  before_action :set_index

  def index
    if stale? blob = @index.versions_blob
      stream_from blob
    end
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
