class Namespaces::ProfilesController < ApplicationController
  before_action :set_index

  def show
    @gems = @index.gems.where.associated(:versions).order(name: :asc).load_async
    @versions = @gems.index_with { _1.versions.select(:ref, :published_at).first(3) }.compact
  end

  private
    def set_index
      @index = Namespace.named(params[:namespace]).external_index
    end
end
