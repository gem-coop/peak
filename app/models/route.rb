module Route
  extend Rails.application.routes.url_helpers

  EmptyRouteSet = Module.new {
    def self.respond_to_missing?(meth) = true
    def self.method_missing(...) = nil
  }

  mattr_reader :avo, default: Peak.avo? ? Avo::Engine.routes.url_helpers : EmptyRouteSet
end
