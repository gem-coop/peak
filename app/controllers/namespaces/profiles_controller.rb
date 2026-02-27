class Namespaces::ProfilesController < ApplicationController
  before_action :set_index

  def show
    @gems = @index.gems.where.associated(:versions).order(name: :asc).load_async
    @versions = @gems.index_with do
      _1.versions.select(:ref, :summary, :published_at, :created_by_id).includes(:created_by).first
    end.compact
  end

  private
    def set_index
      @index = Namespace.named(params[:namespace]).external_index
    end
end
