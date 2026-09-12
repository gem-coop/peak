class SyncDisposableEmailListJob < ApplicationJob
  queue_as :low

  retry_on HTTPX::Error, wait: :polynomially_longer, attempts: 5

  discard_on Peak::DisposableEmailList::InvalidListError do |_job, error|
    Rails.error.report error, handled: false
  end

  def perform
    Peak::DisposableEmailList.sync
  end
end
