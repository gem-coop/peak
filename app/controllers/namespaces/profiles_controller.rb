class Namespaces::ProfilesController < ApplicationController
  block_public_namespace_access
  before_action :set_index

  def show
    @gems = @index.gems.load_async
    @versions = @gems.index_with { _1.versions.select(:ref, :published_at).order(ref: :desc).first(3) }
  end

  private
    def set_index
      @index = Namespace.named(params[:namespace]).external_index
    end
end
