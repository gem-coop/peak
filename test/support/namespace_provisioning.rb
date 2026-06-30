module NamespaceProvisioning
  Publisher = Data.define(:namespace, :token)

  def provision_publisher(namespace_name, as:, name: "Owner")
    user = register(as, requesting: namespace_name, name:)
    verify_email user
    Publisher.new(namespace: approve(namespace_name), token: push_key_for(user))
  end

  def register(email_address, requesting:, name: "Owner")
    post user_sign_ups_url, params: { user_sign_up: { name:, email_address:, namespace_name: requesting } }
    User.find_by!(email_address:)
  end

  def verify_email(user)
    get user_email_verification_url(user.email_verification.token)
    user.reload
  end

  # What Avo::Actions::Approve does.
  def approve(namespace_name)
    submission = Namespace::Submission.find_by!(name: namespace_name)
    perform_enqueued_jobs do
      submission.resolve! :approved
      submission.process_approved
    end
    Namespace.named(namespace_name)
  end

  def push_key_for(user)
    # One key per 30 seconds per IP, and a flow can mint several.
    Rails.application.config.action_controller.cache_store.clear
    post user_push_keys_url, params: { email_address: user.email_address }
    user.reload.push_key.token
  end

  def publish(publisher, package)
    perform_enqueued_jobs { gem_push publisher.namespace, package, token: publisher.token }
    assert_response :success
  end

  def published_version(namespace, name, ref)
    namespace.stable_index.gems.find_by!(name:).versions.find_by!(ref:)
  end
end
