class Namespaces::IndexController < Public::BaseController
  before_action :set_routed_index
  before_action { fresh_when @index, public: @index.public_access? }

  def index
    render plain: @index.contents
  end

  def show
    stream_lines_from @index.versions.for(params[:id])
    head :not_found unless performed?
  end
end
