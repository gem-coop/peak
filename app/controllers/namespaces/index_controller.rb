class Namespaces::IndexController < Public::BaseController
  before_action :set_routed_index
  before_action { fresh_when @index, public: @index.public_access? }

  def index
    render plain: @index.contents
  end

  def show
    plain = @index.versions.latest_last.by_gem(params[:id]).lines
    render plain:, status: (:not_found if plain.empty?)
  end
end
