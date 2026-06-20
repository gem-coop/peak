class Namespaces::ProfilesController < ApplicationController
  resume_authenticated
  before_action :set_index

  def show
    @gems = @index.gems.where.associated(:versions).order(name: :asc).load_async
    @versions = @gems.index_with { _1.versions.latest_first.as_byline.first }.compact
  end

  private
    def set_index
      @index = Namespace.named(params[:namespace]).default_index
    end
end
