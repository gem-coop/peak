class Namespaces::MirrorController < Public::BaseController
  before_action { @index = Namespace.named("@public").external_index }

  def versions
    render plain: @index.versions_contents if stale? @index
  end

  def info
    if stale? info = @index.gems.named(params[:id]).info
      render plain: info.contents
    end
  end

  def gems
    redirect_to "https://gem.coop/gems/#{params[:id]}", allow_other_host: true
  end
end
