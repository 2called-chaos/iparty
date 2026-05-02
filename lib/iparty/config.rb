# frozen_string_literal: true

module IParty
  Config = Struct.new(
    :account_id,
    :license_key,
    :mirror,
    :directory,
    :editions,
    :eager_load,
    :singletons,
    :local_ip_alias,
    :ipv6_significant,
    :url_to_mmdb,
    keyword_init: true,
  ) do
    def singletons=(val)
      self[:singletons] = val
      init_singletons! if val == true
    end

    def init_singletons!
      self[:singletons] = {} if !self[:singletons] || self[:singletons] == true

      editions.each {|edition| IParty::MaxMind.db(edition) }
      self[:singletons]
    end

    def env_value *args, **kw, &block
      IParty.env_value(*args, **kw, &block)
    end
  end

  class << self
    attr_accessor :config

    def configure
      yield(config)
    end

    def env_value key, default = nil, &vproc
      env_value = ENV.fetch(key, default)

      env_value = case env_value
      when "1", "true", "on", "yes" then true
      when "0", "false", "off", "no" then false
      when "" then nil
      else env_value
      end

      vproc ? vproc.call(env_value) : env_value
    end

    def with_config to_merge = {}, &block
      config_was = @config
      new_config = Config.new(config_was.to_h.merge(to_merge))

      if block
        begin
          block.call(self.config = new_config)
        ensure
          self.config = config_was
        end
      else
        new_config
      end
    end

    def default_config
      Config.new(
        # If set to false drop last half of v6-addresses as they are insignificant for most applications.
        # The then 64-bit addresses also fit into unsigned bigints allowing for easy range representations.
        # Each IParty::Address can overwrite this with
        #   * #ipv6_significant accessors
        #   * significant: keyword (affected methods only but including new/initialize)
        ipv6_significant: env_value("IPARTY_IPV6_SIGNIFICANT", true),

        # Whether to use the low memory file reader or load mmdb into memory as a whole (see docs/BENCHMARK.md)
        eager_load: env_value("IPARTY_EAGER_LOAD", false),

        # Singleton instances (may be false, true, hash or proc which returns hash-like)
        singletons: env_value("IPARTY_SINGLETONS", false),

        # An IP that is used instead of local IPs
        local_ip_alias: env_value("IPARTY_LOCAL_IP_ALIAS", nil),

        # MaxMind account_id and license_key aka mirror basic-auth
        account_id: env_value("MAXMIND_ACCOUNT_ID", nil),
        license_key: env_value("MAXMIND_LICENSE_KEY", nil),

        # Mirror to download tar.gz compressed mmdb-files from
        mirror: env_value("MAXMIND_MIRROR", "https://download.maxmind.com/geoip/databases/:edition/download?suffix=tar.gz"),

        # The mmdb editions to fetch, you don't really need country if you have city
        editions: env_value("MAXMIND_EDITIONS", "GeoLite2-ASN GeoLite2-Country GeoLite2-City") {|v| v.split(/\s+|,\s*/) },

        # Directory to store mmdb-files in, also creates .updating subdirectory
        directory: env_value("IPARTY_DIRECTORY", nil) do |dir|
          if dir && !dir.empty?
            Pathname.new(dir)
          else
            Pathname.new(Dir.tmpdir).join("iparty")
          end
        end,

        # Proc to turn URL into mmdb-file(s) inside target directory.
        # All .mmdb files will be moved and then dir gets removed.
        url_to_mmdb: proc do |url, dir, config|
          auth = %{-u "#{config.account_id}:#{config.license_key}"} if config.account_id && config.license_key
          curl = %{curl -L -s #{"#{auth} " if auth}"#{url}"}
          tar = %{tar xz --strip-components 1 --exclude "*.txt" --no-same-owner -C #{dir.to_s.shellescape}}
          system("#{curl} | #{tar}")
        end,
      )
    end
  end
end
