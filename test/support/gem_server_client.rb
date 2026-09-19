module GemServerClient
  # Bundler: GET /<ns>/versions -> { "peak" => ["0.1.0"], "oaken" => ["0.9.1", "1.0.0"] }
  def compact_index_versions(namespace, index: nil)
    get namespace_versions_url(namespace:, index:)
    assert_response :success
    response.body.scan(/^(\S+) (\S+) [0-9a-f]{32}$/).each_with_object(Hash.new { |h, k| h[k] = [] }) do |(name, version), gems|
      gems[name] << version
    end
  end

  # Bundler: GET /<ns>/info/<gem> -> ["0.1.0", ...] (the versions it lists)
  def compact_index_info(namespace, gem)
    get namespace_info_url(namespace:, id: gem)
    assert_response :success
    response.body.scan(/^(\S+) /).flatten
  end

  # Bundler: GET /<ns>/gems/<file> -> the parsed gemspec (fails on a non-2xx response).
  def fetch_gem(namespace, version)
    get namespace_gems_url(namespace:, id: version)
    assert_response :success
    peak_upload_from(response.body).spec
  end

  # RubyGems: POST /<ns>/api/v1/gems with a bearer token (returns the raw response).
  def gem_push(namespace, package, token:)
    post namespace_gem_push_url(namespace:),
      env: { "RAW_POST_DATA" => package, authorization: "Bearer #{token}" }
  end
end
