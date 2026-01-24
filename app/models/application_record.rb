class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def self.has_remote_text_blob(name, **)
    belongs_to(name, class_name: "Peak::Blob::Text", **)

    class_eval <<~RUBY
      def #{name}=(value)
        super Peak::Blob::Text.from(value, filename: "#{name}.txt")
      end
    RUBY
  end
end
