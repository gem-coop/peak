class Namespaces::Gems::ProfilesController < ApplicationController
  before_action :set_index

  def show
    @gem = @index.gems.named(params[:id])
  end

  private
    def set_index
      @index = Namespace.named(params[:namespace]).default_index
    end
end
