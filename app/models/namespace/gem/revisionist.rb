class Namespace::Gem::Revisionist < ActiveRecord::AssociatedObject
  performs def backdate_published_at
    ref_correlated_published_ats.each do |ref, published_at|
      gem.versions.where(ref:).update_all(published_at:)
    end
  end

  private
    def ref_correlated_published_ats
      CooldownVersion::Server.versions_json(gem.name)
        .to_h { _1.values_at("number", "created_at") }.compact
    end
end
