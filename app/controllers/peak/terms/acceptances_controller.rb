class Peak::Terms::AcceptancesController < ApplicationController
  require_authentication
  before_action :set_latest_terms_or_redirect, only: :create

  def new
    @terms = Peak::Terms.latest
  end

  def create
    acceptance = @terms.acceptance_for(Current.user)
    acceptance.capture **params.expect(acceptance: [:accepted, :time_zone]).to_h.symbolize_keys

    if acceptance.accepted?
      Peak::Ok("Terms of Service accepted! Thank you.")
    else
      Peak::Error("Terms of Service denied.")
    end
  end

  private
    def set_latest_terms_or_redirect
      @terms = Peak::Terms.latest

      if @terms.id.to_s != params[:id]
        redirect_to new_terms_acceptances_path, alert: "We've updated our terms since you tried to accept them. Try again."
      end
    end
end
