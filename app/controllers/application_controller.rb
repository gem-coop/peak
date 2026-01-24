class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private
    def stream_from(io)
      io.download do |chunk|
        response.stream.write chunk
      end
    ensure
      response.stream.close
    end
end
