class Namespaces::IndexController < ApplicationController
  before_action :set_namespace

  def index
    render plain: @namespace.gems.pluck(:name).map { |n| "#{n} 0 unknown" }.join("\n")
  end

  def show
    gem = @namespace.gems.find_by!(name: params[:id])

    render plain: gem.versions.order(:ref).map(&:line).join
  end

  private
    def set_namespace
      @namespace = Namespace.named(params[:namespace])
    end
end
