require "test_helper"

class Peak::EmailAddress::DisposedDomainTest < ActiveSupport::TestCase
  def klass = Peak::EmailAddress::DisposedDomain

  test "import" do
    stub_imports_response body: "domain-name.com\n"

    assert_increments(klass) { klass.import }
    assert klass.include?("domain-name.com")
  end

  test "import 404" do
    stub_imports_response status: 404
    assert_raises(HTTPX::HTTPError) { klass.import }
  end

  test "include" do
    assert klass.include?(disposed_domains.mail_com.name)
  end

  private
    def stub_imports_response(**)
      WebMock.stub_request(:get, klass::URL).and_return(**)
    end
end
