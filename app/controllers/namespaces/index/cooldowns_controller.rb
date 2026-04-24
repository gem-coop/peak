class Namespaces::Index::CooldownsController < Public::BaseController
  before_action :set_routed_index
  before_action { @cooldown = @index.cooldown or head :not_found }
  before_action { fresh_when @cooldown, public: @index.public_access? }

  def index
    render plain: @cooldown.contents
  end

  def show
    plain = @cooldown.versions.latest_last.by_gem(params[:id]).lines
    render plain:, status: (:not_found if plain.empty?)
  end
end
