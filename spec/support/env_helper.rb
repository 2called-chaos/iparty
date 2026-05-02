# frozen_string_literal: true

module EnvHelper
  def with_env_kv key, value
    had_key = ENV.key?(key)
    v_was = ENV.fetch(key) if had_key
    ENV[key] = value
    yield
  ensure
    ENV[key] = v_was if had_key
  end

  def with_env kv = {}, &block
    kv = kv.to_a if kv.is_a?(Hash)

    opt = kv.shift
    if kv.empty?
      with_env_kv(*opt, &block)
    else
      with_env_kv(*opt) { with_env(kv, &block) }
    end
  end
end

RSpec.configure do |config|
  config.include EnvHelper
end
