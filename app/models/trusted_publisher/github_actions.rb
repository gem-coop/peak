class TrustedPublisher::GitHubActions < TrustedPublisher
  validates :repository_owner, :repository_name, :workflow_filename, presence: true

  def matches?(claims)
    claims["repository_owner"] == repository_owner &&
      claims["repository"] == "#{repository_owner}/#{repository_name}" &&
      workflow_matches?(claims) &&
      optional_matches?(environment, claims["environment"]) &&
      optional_matches?(ref, claims["ref"])
  end

  private
    def workflow_matches?(claims)
      prefix = "#{repository_owner}/#{repository_name}/.github/workflows/"
      job_ref = claims["job_workflow_ref"].to_s
      return false unless job_ref.start_with?(prefix)
      job_ref.delete_prefix(prefix).split("@", 2).first == workflow_filename
    end

    def optional_matches?(configured, claim_value)
      configured.blank? || configured == claim_value
    end
end
