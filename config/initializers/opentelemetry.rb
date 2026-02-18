if ENV["OTEL_SERVICE_NAME"].present?
  OpenTelemetry::SDK.configure(&:use_all)
end
