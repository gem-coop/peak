class Namespaces::MirrorController < Public::BaseController
  before_action do
    @index = Namespace.named(params[:namespace]).external_index
  end

  def versions
    render_ranged @index.versions_contents if stale? @index
  end

  def info
    if stale? info = @index.gems.named(params[:id]).info
      render_ranged info.contents
    end
  end

  def gems
    redirect_to "https://gem.coop/gems/#{params[:id]}", allow_other_host: true
  end
end
