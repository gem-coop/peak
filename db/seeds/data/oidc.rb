oidc_providers.label github: OIDC::Provider::GitHubActions.create_or_find_by!(
  issuer: OIDC::Provider::GitHubActions::ISSUER
) { _1.name = "GitHub Actions" }
