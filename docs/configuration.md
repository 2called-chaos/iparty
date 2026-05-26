# IParty

## Configuration

You may configure and extend IParty in an initializer or in the init part of your non-rails app.
For basic usage you only really need MaxMind credentials to download the mmdb files.

```ruby
defined?(IParty) && IParty.configure do |config|
  config.account_id = config.env_value("MAXMIND_ACCOUNT_ID", nil)
  config.license_key = config.env_value("MAXMIND_LICENSE_KEY", nil)
end
```



### Easily extend your custom accessors

For more info on extending address or result data look at docs/maxmind_result.md

```ruby
IParty::MaxMind::Result::Geo.class_eval do
  define_attr(:best_tenant, export: true) { country.iso_code == "DE" ? :de : :us }
end

IParty(request.remote_ip).best_tenant # => :us
```



### Full config

This config, minus the CurrentAttributes cache is default config. For basic usage you only need account_id/license_key.
Please also take a look at docs/maxmind_result.md for extending the address and geo results.

```ruby
defined?(IParty) && IParty.configure do |config|
  # If set to false drop last half of v6-addresses as they are insignificant for most applications.
  # The then 64-bit addresses also fit into unsigned bigints allowing for easy range representations.
  # Each IParty::Address can overwrite this with
  #   * #ipv6_significant accessors
  #   * significant: keyword (affected methods only but including new/initialize)
  config.ipv6_significant = config.env_value("IPARTY_IPV6_SIGNIFICANT", true)

  # Whether to use the low memory file reader or load mmdb into memory as a whole (see docs/benchmark.md)
  config.eager_load = config.env_value("IPARTY_EAGER_LOAD", false)

  # Use singleton instances of MaxMind::Database readers.
  # These are lazily initialized so in a threaded environment or with eager load enabled you should pre-init them.
  # Side Effect: You will have to reboot your app for mmdb changes to take effect.
  config.singletons = config.env_value("IPARTY_SINGLETONS", false)
  #config.singletons = {} # lazy load singleton instances, not thread-safe
  #config.singletons = true # eagerly init all editions (eager_load into memory if enabled, thread-safe after init)

  # alternatively you can do something like this:
  # * singleton DB instances (lazily memoized) per-request (eager load should be disabled)
  # * IParty::Address cache (including their geo lookups)
  if defined?(ActiveSupport::CurrentAttributes)
    class IPartyCache < ActiveSupport::CurrentAttributes
      attribute(:databases, default: {})

      # cached IParty addresses, i.e. IPartyCache.ips["1.2.3.4"]
      # Be wary of mutating (i.e. mask!), use clones
      attribute(:ips, default: -> { Hash.new{|h, ip| h[ip.to_s] = IParty(ip.to_s) } })
    end
    config.singletons = -> { IPartyCache.databases }
  end

  # An IP that is used instead of local IPs
  config.local_ip_alias = config.env_value("IPARTY_LOCAL_IP_ALIAS", nil)

  # MaxMind account_id and license_key aka mirror basic-auth
  config.account_id = config.env_value("MAXMIND_ACCOUNT_ID", nil)
  config.license_key = config.env_value("MAXMIND_LICENSE_KEY", nil)

  # Mirror to download tar.gz compressed mmdb-files from
  config.mirror = config.env_value("MAXMIND_MIRROR", "https://download.maxmind.com/geoip/databases/:edition/download?suffix=tar.gz")

  # Editions
  config.editions = config.env_value("MAXMIND_EDITIONS", "GeoLite2-ASN GeoLite2-Country GeoLite2-City") {|v| v.split(/\s+|,\s*/) }

  # Target directory (for mmdb files, will also create subdirectory for updating)
  # Note: Must be a pathname
  config.directory = config.env_value("IPARTY_DIRECTORY", nil) do |dir|
    if dir && !dir.empty?
      Pathname.new(dir)
    elsif defined?(Rails)
      Rails.root.join("vendor", "maxmind")
    else
      Pathname.new(Dir.tmpdir).join("iparty")
    end
  end

  # Proc to download mmdb files
  config.url_to_mmdb = proc do |url, dir, config|
    auth = %{-u "#{config.account_id}:#{config.license_key}"} if config.account_id && config.license_key
    curl = %{curl -L -s #{"#{auth} " if auth}"#{url}"}
    tar = %{tar xz --strip-components 1 --exclude "*.txt" --no-same-owner -C #{dir.to_s.shellescape}}
    system("#{curl} | #{tar}")
  end

  # --- following is example code and not default behaviour ---

  # Proc to transform geo result data, by default does nothing.
  # yields
  #   data          the result hash
  #   addr          the looked up address (as IParty or IPAddr)
  #   result_class  the class that later will get instantiated with data
  config.transform_result = proc do |data, addr, result_class|
    if addr.loopback?
      data[:country] ||= { iso_code: "ZZ", names: { en: "Local" } }
      data[:continent] ||= { code: "ZZ", names: { en: "Local" } }
    end
  end

  # For more info on extending look at docs/maxmind_result.md
  IParty::Address.define_method(:detailed) do |*args|
    "#{to_s} -- #{geo.detailed} -- #{asn.detailed}"
  end

  # You may want to rely on rake task and/or ensure on app boot?
  #   fetch_when can be
  #     * :always
  #     * :missing
  #     * (Numeric) maxAge (i.e. (int)seconds or (AS::Duration)14.days)
  IParty.fetch_db_files!(:missing, verbose: true)
end
```



### Annotations

You can annotate IPs or networks with arbitrary data whereas `tags` has special behaviour (they merge).
IParty CLI will display `name` along `tags` in the summarized view.

```ruby
defined?(IParty) && IParty.configure do |config|
  # annotate(*addresses, **data) -- merges data and tags
  IParty.config.annotate "1.0.0.0/8", tags: %i[foo]
  IParty.config.annotate "1.2.3.4", tags: %i[bar]
  IParty.config.annotate "127.0.0.1/8", "::1", name: "loopback", tags: %i[localhost]

  # annotate_tag(tags, *addresses) -- merges tags
  IParty.config.annotate_tag :one, "1.0.0.0/8"
  IParty.config.annotate_tag %i[local ipv4], "127.0.0.1/8"
  IParty.config.annotate_tag %i[local], "127.0.0.1/8", "::1"
end

IParty("127.1.2.3").annotations # => {:name=>"loopback", :tags=>[:localhost, :local, :ipv4]}
```



### Check configuration

You can use the shipped rake tasks to check your effective configuration.

```
# shows effective IParty config (including license_key)
rake iparty:config
rake iparty:config[inspect]
rake iparty:config[json]

# check mmdb file status
rake iparty:status
```
