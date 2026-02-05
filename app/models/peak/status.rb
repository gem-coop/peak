class Peak::Status
  include Peak::Rendering

  attr_reader :status

  def initialize(status)
    @status = status
  end
end
