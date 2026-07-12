class Namespaces::Gems::ProfilesController < ApplicationController
  before_action :set_index

  def show
    @gem = @index.gems.named(params[:id])
    set_breadcrumb_trail @index.namespace, @gem
  end

  private
    def set_index
      @index = Namespace.named(params[:namespace]).stable_index
    end
end
