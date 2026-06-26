class Namespaces::ProfilesController < ApplicationController
  before_action :set_index

  def show
    @gems = @index.gems.where.associated(:versions).order(name: :asc).load_async
    @versions = latest_versions_by_gem(@gems)
  end

  private
    def set_index
      @index = Namespace.named(params[:namespace]).default_index
    end

    # DISTINCT ON: latest version per gem in one query (as_byline columns), kept in @gems' name order.
    def latest_versions_by_gem(gems)
      latest = Namespace::Gem::Version
        .where(gem: gems)
        .select("DISTINCT ON (namespace_gem_versions.gem_id) " \
                "namespace_gem_versions.gem_id, ref, summary, published_at, created_by_id")
        .order(Arel.sql("namespace_gem_versions.gem_id, published_at DESC, ref DESC"))
        .includes(:created_by)
        .index_by(&:gem_id)

      gems.filter_map { |gem| [gem, latest[gem.id]] if latest[gem.id] }.to_h
    end
end
