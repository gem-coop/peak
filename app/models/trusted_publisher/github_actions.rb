class TrustedPublisher::GitHubActions < TrustedPublisher
  # GitHub owner/repo names are case-insensitive; store them folded so matching
  # and uniqueness behave regardless of how the owner typed them in.
  normalizes :repository_owner, :repository_name, with: -> { _1&.downcase }

  validates :repository_owner, :repository_name, :workflow_filename, presence: true
  validates :repository_name, uniqueness: {
    scope: %i[namespace_id type repository_owner workflow_filename environment ref],
    message: "duplicates an existing trusted publisher for this workflow" }

  def matches?(claims)
    claims["repository_owner"].to_s.downcase == repository_owner &&
      claims["repository"].to_s.downcase == "#{repository_owner}/#{repository_name}" &&
      workflow_matches?(claims) &&
      optional_matches?(environment, claims["environment"]) &&
      optional_matches?(ref, claims["ref"])
  end

  def provider_label = "GitHub Actions"

  private
    def workflow_matches?(claims)
      # The owner/repo segment is case-insensitive; the workflow filename is not.
      head, sep, tail = claims["job_workflow_ref"].to_s.partition("/.github/workflows/")
      return false if sep.empty?
      return false unless head.downcase == "#{repository_owner}/#{repository_name}"
      tail.split("@", 2).first == workflow_filename
    end

    def optional_matches?(configured, claim_value)
      configured.blank? || configured == claim_value
    end
end
