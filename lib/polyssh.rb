require "polyssh/version"

module Polyssh
  class Error < StandardError; end
  # Your code goes here...
end

require "polyssh/cli"
require "polyssh/collector"
require "polyssh/executor"
require "polyssh/renderer"
require "polyssh/patches_for_ractor"
