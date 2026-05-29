# IParty

## 0.x.x alpha: risk of party crashers


Makes (geo) IP fun again! Ain't no party like an IParty, because an IParty don't stop.

```ruby
IParty.fetch_db_files! # api key required
ip = IParty(request.remote_ip)

# all these are true
ip.country.de?
ip.country.germany?
ip.country.in_european_union?
ip.country.is_a?(Hash)
ip.country == "Germany" # 🤨
```

* IParty handles download\* and decoding of, and lookup in, mmdb-files (\* = shelling to curl and tar)
* IParty lets you annotate IPs/networks with arbitrary helpers, data and tags
* IParty lets you ignore the MAC address part of an ipv6 address more easily
* IParty has *no*\* dependencies (\* = stdlib dependencies: fileutils, forwardable, ipaddr, pathname, tmpdir, optparse)
* IParty is essentially a fork/refactor of the [maxminddb](https://github.com/yhirose/maxminddb) gem.
  The reimaginated implementation details were however too party for a pull request in my opinion.
* IParty parties hard!


## IParty CLI utility

IParty ships with a cli utility `iparty`, refer to [docs/cli/README.md](docs/cli/README.md) for more information.



## Start partying

### Requirements

```ruby
spec.required_ruby_version = ">= 3.2.0"
```


### Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add iparty
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install iparty
```


### Configuration

These default settings should or could be changed at "boot" (i.e. in an initializer):

```ruby
defined?(IParty) && IParty.configure do |config|
  config.account_id = config.env_value("MAXMIND_ACCOUNT_ID", nil)
  config.license_key = config.env_value("MAXMIND_LICENSE_KEY", nil)
end
```

There are more ways to configure and/or customize IParty.
You can also change most of these settings via ENV variables.

See [docs/configuration.md](docs/configuration.md) for more information.


### Usage

#### Fetching mmdb-files

Note: This requires a unix-oid environment with curl, tar and gzip available.
      You may change the download process.
      For more information see [docs/configuration.md](docs/configuration.md) and [docs/mmdb_download.md](docs/mmdb_download.md)

Either in your application startup, and/or in a rake task:

```ruby
IParty.fetch_db_files! # always download a fresh copy
IParty.fetch_db_files!(:missing) # only download missing files
IParty.fetch_db_files!(14 * 24 * 60 * 60) # only download missing or expired files (14.days also works with ActiveSupport)
```

You may also use the shipped rake tasks for this purpose:

```ruby
rake iparty:fetch
rake iparty:fetch[14.days] # or int-seconds without AS
rake iparty:update
```

Outside of Rails you need to register them manually in your Rakefile:

```ruby
require "iparty/rake_task"
IParty::RakeTask.new
```


#### Basic usage

```ruby
ip = IParty("1.2.3.4") # shorthand for IParty.normalize
ip.as_json

# all these are true
ip.country.de?
ip.country.germany?
ip.country.in_european_union?
ip.country.is_a?(Hash)
ip.country == "Germany" # 🤨
ip.country == 123_345 # you may want to read the docs at this point lol
ip.country.names.de == "Deutschland"
ip.country.name(:es, fallback_locale: :fr) == "Germany"
ip.country.dig(:names, :en) == "Germany"
```

You should definitely take a quick look at the documentation, specifically about the [MaxMind::Result](docs/maxmind_result.md) object.
It should be intuitive magic but you may scratch your head if you "don't get it".



## Further reading

  * [docs/benchmark.md](docs/benchmark.md)
  * [docs/configuration.md](docs/configuration.md)
  * [docs/exceptions.md](docs/exceptions.md)
  * [docs/maxmind_result.md](docs/maxmind_result.md)
  * [docs/mmdb_download.md](docs/mmdb_download.md)



## Compatibility to maxminddb gem

IParty is somewhat compatible with (read: replacing) maxminddb depending on your usage. Most notably the result data hash is symbolized.



## Development

* Check out the repository
* Run `bin/setup` to install dependencies
* Run `bin/console` to experiment with an interactive irb prompt
* Run `rake` to run all the tests
* Run `rake ci` to fetch mmdb-files, then run all the tests (more coverage)

In order to run all the tests you must have API credentials for MaxMind (or a mirror / local copy of the mmdb files for Country, City and ASN).
The mmdb-files can no longer be distributed or downloaded without API credentials due to licensing. See Configuration.



## Contributing

Bug reports, ideas, feedback and pull requests are welcome on GitHub at https://github.com/2called-chaos/iparty.

* [Open an issue](https://github.com/2called-chaos/iparty/issues/new)

or

1. [Fork it](http://github.com/2called-chaos/iparty/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Make sure the tests pass and test your changes too (`rake` or `rake ci`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request



## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT), see [LICENSE.txt](https://github.com/2called-chaos/iparty/blob/master/LICENSE.txt).



## Legal

* © 2014, yhirose [maxminddb](https://github.com/yhirose/maxminddb) and contributors
* © 2026, Sven Pachnit (www.bmonkeys.net) and contributors
* iparty is licensed under the MIT license
