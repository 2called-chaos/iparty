# IParty

## MaxMind Result

Result is_a?(Hash) with some magic sprinkled in, party!

* Defined attributes can be retrieved via method(chaining)
* Even without ActiveSupport core_ext, Result(Hash) and Subdivisions(Array) implements blank?/present?/presence (values do not however)
* Dynamically compares
  * result == Numeric => geoname_id
  * result == String => name.en
* Dynamically inquires
  * result.us? (2-char checks against code on continent or iso_code otherwise)
  * result.foo? (!2-char checks against english name (lowercased, underscored))



### Class Structure

```ruby
IParty::MaxMind::Result < Hash
  Asn < Result
  Geo < Result
    GeoCountry < Geo
    GeoCity < Geo

  Subdivisions < Array
  Location < Result
  NamedLocation < Result
    Continent < NamedLocation
    Country < NamedLocation
    City < NamedLocation
    Subdivision < NamedLocation
  Postal < Result
  Traits < Result
```

Note: There's little reason to define attributes on GeoCountry or GeoCity since by default country is the fallback of city lookups.
You should therefore define attributes on Geo and make sure they work with nil data to preserve safe navigation access.



### Add methods

You can (in an initializer) add your own representations and helpers to the result classes or address class.

```ruby
# define_attr is a helper to define accessors on the result data with the following synopsis:
#   define_attr(
#     name,                  # The method name
#     attribute = name,      # The attribute to dig
#     type: nil,             # sugar for transform ->(v) { type.new(v) }
#     aliases: nil,          # Symbol or Array[Symbol] of alias method names
#     memoize: nil,          # Memoize the value (true/false, nil: true if transform block is given)
#     export: nil,           # True, Symbol or Array[Symbol] of method names to export to Address (def_delegate)
#                            # Note: Only works on Result/Geo(Country/City)/Asn
#     &transform             # The value to return, if omitted it's the digged value
#   )

IParty::MaxMind::Result::Geo.define_attr(:best_tenant, export: true) { continent.eu? ? :eu : :us }
IParty::MaxMind::Result::Geo.define_attr(:short, export: true) { [continent.code, country.name].compact.join(" / ") }
IParty::MaxMind::Result::Asn.define_attr(:short, export: :asn_short) { "AS#{number} #{organization}" }
IParty::Address.define_method(:detailed) { "#{to_s} -- #{geo.detailed} -- #{asn_short}" }
# IParty(ip).short/asn_short/detailed

# Delegate geo/asn methods so you can do `ip.METHOD` instead of `ip.geo.METHOD`
IParty::Address.def_delegators(:geo, *%i[registered_country])
IParty::Address.def_delegators(:asn, *%i[network])
# Note that some are already exported, namely:
#   * city
#   * continent
#   * country
#   * in_european_union?
#   * latitude
#   * longitude
#   * time_zone
#   * postal_code
#   * (asn) autonomous_system_network
#   * (asn) autonomous_system_number
#   * (asn) autonomous_system_organization
#   * (asn) autonomous_system_detailed
```
