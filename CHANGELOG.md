## [Unreleased]

* Allow arbitrary data on annotation hash by using a Symbol as key
* Fix: `significant: true` option on insignificant ipv6 IParty::Address#size
* Test all methods with significant keyword on equality



## [0.1.4] - 2026-05-30

* Add to ASN `define_attr(:autonomous_system_name, aliases: :name, export: true) { "AS#{number}" if number }`
* Add ipaddr (stdlib) dependency
* Add shellwords (stdlib) dependency



## [0.1.3] - 2026-05-29

* Fix: Correctly re-normalize insignificant ipv6 IParty::Address
* Fix: `significant: true` option on insignificant ipv6 IParty::Address#to_s
* Add `IParty.normalize_family` to allow all of Socket constant, 4/6 or :ipv4/:ipv6
* Add `IParty.insignificant(long)` and `IParty::Address.from_insignificant(long)` to get address from insignificant ipv6-long
* `IParty.normalize`, when given an integer as address, will accept as family: 4 6 :ipv4 :ipv6 (also Socket::AF_INET Socket::AF_INET6 as before)
* `IParty.config.singletons = true` will no longer cause immediate init of database objects. Use `IParty.config.init_singletons!` after you've set all options if you want "true behaviour".
  If the value is set to true `init_singletons!` will be called the first time a database object is initialized.
* Compact input to expand_hostnames
* Add dev script to test performance with rbspy
* [doc] Add CurrentAttribute example for AS<8
* [cli] Add cookbook helper
* [cli] Show dispatchable actions in verbose appinfo



## [0.1.2] - 2026-05-27

* Include documentation in gem package
* Automatically set a network for localhost
* Add config option (proc) transform_result
* iso_code fallbacks to code and vice versa so you don't have to think about it (continent has code and rest has iso_code).
  This only applies to method access, `[:code]` does not fallback.
* Add alias `timezone` for `time_zone`
* Memoize annotations
* Add `tag?` helper for annotations



## [0.1.1] - 2026-05-26

* Add missing pathname dependency (stdlib)
* Add `IParty::GEM_ROOT` pathname



## [0.1.0] - 2026-05-26

* Initial release
