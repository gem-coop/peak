class SeedGithubActionsProvider < ActiveRecord::Migration[8.1]
  ISSUER = "https://token.actions.githubusercontent.com"

  # Seed via raw SQL rather than the application model: a migration must keep
  # running against future code, where the model may be renamed or revalidated.
  def up
    # Seeding data is safe; strong_migrations can't inspect raw execute, so assert it.
    safety_assured do
      execute(<<~SQL)
        INSERT INTO oidc_providers (issuer, name, type, created_at, updated_at)
        VALUES (#{quote(ISSUER)}, 'GitHub Actions', 'OIDC::Provider::GitHubActions', NOW(), NOW())
        ON CONFLICT (issuer) DO NOTHING
      SQL
    end
  end

  def down
    safety_assured { execute("DELETE FROM oidc_providers WHERE issuer = #{quote(ISSUER)}") }
  end

  private
    def quote(value) = ActiveRecord::Base.connection.quote(value)
end
