class Namespaces::CooldownController < Public::BaseController
  before_action do
    @index = Namespace.named(params[:namespace]).external_index.cooldown(48.hours)
    render no_data if @index.gems.empty?
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

  private

  def no_data
    render plain: "Gem dates not yet imported, cannot serve cooldowns", status: 500
  end
end
