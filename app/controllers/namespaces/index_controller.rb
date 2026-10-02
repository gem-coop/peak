class Namespaces::IndexController < Public::BaseController
  before_action :set_routed_index
  before_action { fresh_when @index, public: @index.public_access? }

  def index
    render plain: @index.contents
  end

  def show
    plain = @index.versions.for(params[:id]).lines
    render plain:, status: (:not_found if plain.blank?)
  end
end
