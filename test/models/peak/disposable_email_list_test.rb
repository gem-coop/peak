require "test_helper"

class Peak::DisposableEmailListTest < ActiveSupport::TestCase
  setup do
    @expected_size = Peak::DisposableEmailList.expected_size
    Peak::DisposableEmailList.expected_size = 2..10
  end
  teardown { Peak::DisposableEmailList.expected_size = @expected_size }

  test "sync blocks the listed domains" do
    stub_list "mailinator.com\nguerrillamail.com\n"

    assert_increments Peak::BlockedDomain, by: 2 do
      Peak::DisposableEmailList.sync
    end

    assert_equal %w[guerrillamail.com mailinator.com], Peak::BlockedDomain.disposable_email_list.pluck(:name).sort
  end

  test "sync skips comments, blanks, duplicates and unregistrable entries" do
    stub_list "# a comment\n\n  MAILINATOR.com  \ncom\nnope\nmailinator.com\nspam4.me\n"

    Peak::DisposableEmailList.sync

    assert_equal %w[mailinator.com spam4.me], Peak::BlockedDomain.disposable_email_list.pluck(:name).sort
  end

  test "sync drops domains the list no longer holds" do
    stub_list "mailinator.com\nguerrillamail.com\n"
    Peak::DisposableEmailList.sync

    stub_list "mailinator.com\nspam4.me\n"
    Peak::DisposableEmailList.sync

    assert_equal %w[mailinator.com spam4.me], Peak::BlockedDomain.disposable_email_list.pluck(:name).sort
  end

  test "sync leaves hand added rows alone" do
    stub_list "mailinator.com\n#{blocked_domains.mail_com.name}\n"

    Peak::DisposableEmailList.sync

    assert blocked_domains.mail_com.reload.manual?
  end

  test "sync refuses a list that shrank too much" do
    stub_list %w[mailinator.com guerrillamail.com spam4.me yopmail.com trashmail.com sharklasers.com].join("\n")
    Peak::DisposableEmailList.sync

    stub_list "mailinator.com\nguerrillamail.com\n"
    assert_raises(Peak::DisposableEmailList::InvalidListError) { Peak::DisposableEmailList.sync }

    assert_equal 6, Peak::BlockedDomain.disposable_email_list.count
  end

  test "sync refuses a list that is too short or too long" do
    stub_list "mailinator.com\n"
    assert_raises(Peak::DisposableEmailList::InvalidListError) { Peak::DisposableEmailList.sync }

    stub_list Array.new(11) { "spam#{_1}.com" }.join("\n")
    assert_raises(Peak::DisposableEmailList::InvalidListError) { Peak::DisposableEmailList.sync }

    assert_empty Peak::BlockedDomain.disposable_email_list
  end

  test "sync refuses a list holding a major email provider" do
    stub_list "mailinator.com\ngmail.com\n"

    assert_raises(Peak::DisposableEmailList::InvalidListError) { Peak::DisposableEmailList.sync }
    assert_empty Peak::BlockedDomain.disposable_email_list
  end

  test "sync refuses a failing response" do
    stub_request(:get, Peak::DisposableEmailList::URL).to_return(status: 500)

    assert_raises(HTTPX::HTTPError) { Peak::DisposableEmailList.sync }
    assert_empty Peak::BlockedDomain.disposable_email_list
  end

  private
    def stub_list(body) = stub_request(:get, Peak::DisposableEmailList::URL).to_return(body:)
end
