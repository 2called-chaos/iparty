# IParty

## Download of mmdb-files

Note: You need to configure valid credentials and/or mirror, see Configuration.


---


### Download method

By default IParty will use this proc (and you may change it) to turn a URL (to a gz compressed mmdb-file) to a mmdb-file inside the temporary directory.

Note: This requires a unix-oid environment with curl, tar and gzip available.

```ruby
IParty.config.url_to_mmdb = proc do |url, dir, config|
  auth = %{-u "#{config.account_id}:#{config.license_key}"} if config.account_id && config.license_key
  curl = %{curl -L -s #{"#{auth} " if auth}"#{url}"}
  tar = %{tar xz --strip-components 1 --exclude "*.txt" --no-same-owner -C #{dir.to_s.shellescape}}
  system("#{curl} | #{tar}")
end
```


The file fetching process will

* download all editions (`IParty::MaxMind.editions`) in sequence, extract them flat into the temporary directory
  * the MaxMind account_id and license_key are HTTP Basic Auth username and password (this also works for your mirror)
* move all mmdb files inside the temp directory into the data directory
  * this is essentially an atomic-ish update and will not nuke your existing files on error
  * files that failed to download or are no longer requested will remain (no cleanup)
* remove the temp directory



### Download

#### Ruby

In your application startup, or in a rake task:

```ruby
# only download missing or expired files
IParty.fetch_db_files!(14 * 24 * 60 * 60) # or 14.days

# only download missing files, verbose will print files downloaded to stderr
IParty.fetch_db_files!(:missing, verbose: true)

# always download a fresh copy
IParty.fetch_db_files! # (:always)
```


#### Rake tasks

You may also use the shipped rake tasks for this purpose:

```ruby
rake iparty:fetch
rake iparty:fetch[14.days] # or int-seconds without AS
rake iparty:update
```

There are also these rake tasks
```ruby
# prints mmdb file status, expiry check if max_age is provided
# will exit(1) if any file is missing, invalid or expired
rake iparty:status
rake iparty:status[14.days]

# shows effective IParty config (including license_key)
rake iparty:config
rake iparty:config[inspect]
rake iparty:config[json]
```

Outside of Rails you need to register them manually in your Rakefile:

```ruby
require "iparty/rake_task"
IParty::RakeTask.new
```
