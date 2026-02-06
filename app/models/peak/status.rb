class Peak::Status
  include Peak::Rendering
  self.to_partial_path = "peak/statuses/status"

  attr_reader :message

  def initialize(message)
    @message = message
  end
end
