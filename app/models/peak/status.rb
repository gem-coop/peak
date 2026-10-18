class Peak::Status
  include Peak::Rendering

  attr_reader :message

  def initialize(message)
    @message = message
  end
end
