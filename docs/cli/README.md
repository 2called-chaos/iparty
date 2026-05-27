# IParty CLI utility

```
Usage: iparty <IP|host...> [options]

# Application options
    -a, --[no-]all                         full non-summarized output
    -f, --format <FORMATTER>               formatter (pretty|json|off) or template string [default: pretty]
    -l, --language <LANG>                  limit output to language (or all) [default: en]
    -r, --[no-]resolve                     resolve hosts and include hostnames in data (requires resolv)
    -o, --only   key,deep.key,*country*    list of key expressions (grep on full key)
    -e, --except key,deep.key,sub*         list of key expressions (grep_v on full key)
                                           ** matches .*
                                            * matches [^.]*
        --[no-]stdin                       read from stdin (one IP per line)

# (Custom) actions
    -d, --dispatch ACTION                  Dispatch given action, you may add your own
        --irb                              IRB repl with iparty context and helpers

# MMDB actions
        --mmdb-status                      Show mmdb file status
        --mmdb-fetch                       Fetch missing mmdb-editions
        --mmdb-update                      Update all mmdb-editions

# General options
    -h, --help                             Shows this help
    -v, --version                          Shows version and mmdb info (and config with --debug)
    -m, --[no-]monochrome                  Don't or do colorize output
        --[no-]debug                       Enable debug, raise exceptions and print config with -v
        --no-rc                            Do not eval config.rb

The current config directory is /Users/chaos/.iparty
```



## Configuration

IParty CLI attempts to load a config file (`config.rb`) in `ENV.fetch("IPARTY_CFGDIR", "~/.iparty")` by default, `--no-rc` will skip this.

You can configure application defaults or define custom formatters, actions, or do whatever really. The file will be eval'd in the application context.

Also look at the action cookbook in `docs/cli/action_cookbook`.

```ruby
# Create this file as ~/.iparty/config.rb
# This file is eval'd in the application object's context after it's initialized!


# For IParty options refer to the IParty documentation.
#     https://github.com/2called-chaos/iparty/blob/master/README.md

IParty.config.account_id = "..."
IParty.config.license_key = "..."

# tip: tidy up with offloading to `require_relative "annotations"`
IParty.configure do |config|
  config.annotate "1.1.1.1", "1.0.0.1", tags: %i[cloudflare_dns]
  config.annotate_tag %i[loopback], "127.0.0.1/8", "::1"
end


# Change CLI defaults (arguments will still override)
# For CLI options refer to application/options.rb#default_options
#     https://github.com/2called-chaos/iparty/blob/master/lib/iparty/cli/application/options.rb

@opts[:summarize] = false
@opts[:except] += [
  "registered_country",
  "subdivisions",
]

# This will eval (usable) examples from docs/cli/action_cookbook
cookbook("show_my_remote_ips")



# =================
# = Custom Action =
# =================
# Also look at the action cookbook in `docs/cli/action_cookbook`!

@optparse.separator("\n# Options for --dispatch ban")
@optparse.on("--reason REASON", String, "ban reason") {|v| @opts[:ban_reason] = v }

# iparty -d ban --reason "they suck" 1.2.3.4 c498:81dd:12bc:b812:a2c4:b003:303d:6707
def dispatch_ban
  each_address do |ip|
    ipp = IParty(ip, significant: false)
    puts "ban #{ipp} (#{ipp.geo.detailed}) because #{@opts[:reason]}" # @todo ban ip
  end
end



# ====================
# = Custom Formatter =
# ====================

# Descendants of CLI::Formatter are accessible by their ::id (compared `fmt.id === input`)
#   i.e. self.id = "foo" # --format foo
#   i.e. self.id = /^foo$/
#   i.e. self.id = ->{ _1 == "foo" }
# If no id is specified it will default to the class name (unhandy but accessible)
# You can also list all formatters with `-v --debug`

# The app will call #format for single IPs and #format_all for multiple (or stdin)
# but you may handle them the same way.

class MyFormatter < IParty::CLI::Formatter
  # self.id = "my"

  # def setup
  #   # optional, called at the end of initialize if responds_to?(:setup)
  # end

  # return an array of put-able things (false will be skipped)
  def format_all ips, **kw, &to_data
    ips.map.with_index {|ip, index| format(ip, index: index, **kw, &to_data) }
  end

  # return a put-able thing (or false to skip output)
  # to_data will turn an IP into filtered data according to app-args and opts
  def format ip, index: 0, **kw, &to_data
    "[#{index}] #{to_data.call(ip)}"
  end
end

class MyJsonFormatter < IParty::CLI::Formatter::JsonFormatter
  self.id = "my_json"

  def format ip, index: 0, **kw, &to_data
    if @opts[:foo] == "bar"
      format_all(Array(ip), **kw, &to_data)
    else
      super
    end
  end
end
```
