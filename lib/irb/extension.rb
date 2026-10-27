require "irb/helper_method"

module IRB
  def self.helper(key, description, execute)
    const = Class.new(IRB::HelperMethod::Base)
    const.description(description)
    const.define_method(:execute, &execute)

    const_set "#{key.to_s.classify}Helper", const
    HelperMethod.register(key, const)
  end
end
