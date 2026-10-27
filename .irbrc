require_relative "lib/irb/extension"
IRB.helper :locate, "Runs Namespace::Gem.locate", -> { Namespace::Gem.locate _1 }
