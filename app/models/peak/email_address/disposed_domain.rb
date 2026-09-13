# frozen_string_literal: true

class Peak::EmailAddress::DisposedDomain < ApplicationRecord
  class ImportJob
    def perform = Peak::EmailAddress::DisposedDomain.import
  end

  def self.import
    response = HTTPX.get(URL).raise_for_status

    response.body.read.split("\n").each_slice(1_000) do |domains|
      insert_all domains.map { {name: _1} }, unique_by: :name
    end
  end
  URL = "https://raw.githubusercontent.com/disposable-email-domains/disposable-email-domains/refs/heads/main/disposable_email_blocklist.conf"

  def self.include?(name)
    exists?(name:)
  end
end
