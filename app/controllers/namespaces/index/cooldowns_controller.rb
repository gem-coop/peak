class Namespaces::Index::CooldownsController < Public::BaseController
  before_action :set_routed_index, :set_routed_cooldown
  before_action { fresh_when @cooldown, public: @index.public_access? }

  def index
    render plain: @cooldown.contents
  end

  def show
    stream_lines_from @cooldown.versions.for(params[:id])
    head :not_found unless performed?
  end

  private
    def set_routed_cooldown
      interval  = params[:period_id]&.to_i&.days
      @cooldown = interval ? @index.cooldowns.find_by!(interval:) : @index.cooldowns.first
      head :not_found unless @cooldown
    end
end
