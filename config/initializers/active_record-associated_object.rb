ActiveRecord::AssociatedObject.extend Module.new {
  # Generate a single action ::Mailer representation for the Associated Object.
  #
  #   User::EmailVerification.has_mailer to: :user, subject: "Hello"
  #   # => User::EmailVerification::Mailer with a `mailer` action.
  #   # => app/views/user/email_verification/mailer.{html,text}.erb
  #   # => default_i18n_subject points to `user.email_verification.mailer.subject`
  #
  #   User::EmailVerification.first.mailer # => <User::EmailVerification::Mailer instance>
  #   User::EmailVerification.first.deliver_later # => Schedules the mailer to deliver later.
  #
  #   # If you need more control of the action, pass `action:`:
  #   has_mailer action: -> { mail to: user.email_address, subject: "Hello" }
  #
  #   # If you need more control of the mailer generation pass a block and define `mailer`:
  #   has_mailer do
  #     before_action :set_something
  #
  #     def mailer
  #       mail to: user.email_address, subject: "Hello"
  #     end
  #   end
  #
  #   has_mailer action: -> { mail to: user.email_address, subject: "Hello" } do
  #     before_action :set_something
  #   end
  def has_mailer(to: nil, action: nil, **options, &block)
    # Can't use `const_set :Mailer` because `name` becomes nil. So use `class_eval` to subclass.
    class_eval <<~RUBY
      class Mailer < ApplicationMailer
        helper_method def #{attribute_name} = params.fetch(:#{attribute_name})
        helper_method delegate :#{record.model_name.element}, to: :#{attribute_name}
      end
    RUBY

    mailer = const_get(:Mailer).tap { _1.default template_path: name.underscore }

    action ||= -> { mail to: ActionMailer::Address(public_send(to)), **options } if to
    action ? mailer.define_method(:mailer, &action) : mailer.class_eval(&block)

    define_method(:mailer) { self.class::Mailer.with(self.class.attribute_name => self).mailer }
    delegate :deliver_later, to: :mailer
  end
}
