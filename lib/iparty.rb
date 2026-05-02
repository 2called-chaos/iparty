# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "forwardable"

# rubocop:disable Naming/MethodName
def IParty *args, **kw
  IParty.normalize(*args, **kw)
end
# rubocop:enable Naming/MethodName

module IParty
  class Error < StandardError; end

  require_relative "iparty/version"
  require_relative "iparty/config"
  require_relative "iparty/address"
  require_relative "iparty/max_mind"
  require_relative "iparty/railtie" if defined?(Rails)

  @config = default_config

  def self.normalize input, family = nil, native: false, **kw
    return unless input
    return if input.is_a?(String) && input.match?(/\A[[:space:]]*\z/)
    return if input.respond_to?(:empty?) && input.empty?

    addr = case input
    when String
      Address.new(input.strip, **kw)
    when IPAddr
      Address.new(input.to_i, input.family)
    when Integer
      family ||= input > (2**32) - 1 ? Socket::AF_INET6 : Socket::AF_INET
      Address.new(input, family, **kw)
    else
      raise IPAddr::InvalidAddressError, "invalid address: #{input}"
    end

    native ? addr.native : addr
  end

  def self.classify input
    normalize(input).type
  rescue IPAddr::Error
    :invalid
  end
end
