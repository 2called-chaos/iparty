# frozen_string_literal: true

module IParty
  class MaxMind
    class Result < Hash
      class << self
        def define_attr(name, attribute = name, type: nil, aliases: nil, memoize: nil, export: nil, &transform)
          ivar = :"@#{attribute}"
          transform ||= ->(v) { type.new(v) } if type
          memoize = true if memoize.nil? && transform
          method_names = [name] + Array(aliases)

          method_names.each do |meth|
            define_method(meth) do
              value = dig(attribute)
              return transform ? instance_exec(value, &transform) : value unless memoize
              return instance_variable_get(ivar) if instance_variable_defined?(ivar)

              instance_variable_set(ivar, instance_exec(value, &transform))
            end
          end

          Array(export).each{|exp| export_attr(name, exp == true ? name : exp) }

          method_names
        end

        def export_attr name, export
          if self == Result::Asn
            IParty::Address.def_delegator(:asn, name, export)
          elsif self == Result::Geo || self == Result
            IParty::Address.def_delegator(:geo, name, export)
          else
            raise ArgumentError, "you can only export on Result, Geo(*) and Asn (got #{self})"
          end
        end
      end

      class Location < Result
        define_attr(:accuracy_radius)
        define_attr(:latitude)
        define_attr(:longitude)
        define_attr(:metro_code)
        define_attr(:time_zone, aliases: :timezone)
      end

      class NamedLocation < Result
        define_attr(:code, memoize: false) {|v| v || self[:iso_code] }
        define_attr(:geoname_id)
        define_attr(:is_in_european_union, aliases: :in_european_union?)
        define_attr(:iso_code, memoize: false) {|v| v || self[:code] }
        define_attr(:names, type: Result)

        def name(locale = :en, fallback_locale: :en)
          return unless all = dig(:names)

          all[locale] || (all[fallback_locale] if fallback_locale)
        end

        # dynamic cast
        alias_method :to_s, :name
        alias_method :to_i, :geoname_id

        # dynamic comparison
        def == other
          case other
          when String
            name && other == name
          when Numeric
            geoname_id && other == geoname_id
          else
            super
          end
        end

        # dynamic inquiry
        define_attr(:inquire_on_name) { name&.downcase&.tr(" ", "_") }
        define_attr(:inquire_on_code) { iso_code&.downcase }

        def respond_to_missing? method_name, include_private = false
          method_name.end_with?("?") || super
        end

        def method_missing method_name, *arguments
          if method_name.end_with?("?")
            method_name[0..-2] == (method_name.length == 3 ? inquire_on_code : inquire_on_name)
          else
            super
          end
        end
      end

      class City < NamedLocation
      end

      class Continent < NamedLocation
      end

      class Country < NamedLocation
      end

      class Subdivision < NamedLocation
      end

      class Subdivisions < Array
        def initialize raw
          super((raw || []).map{|hash| Subdivision.new(hash) })
        end

        def inspect
          "#<#{self.class}:#{format("0x%x", object_id << 1)}: #{super}>"
        end

        alias_method :blank?, :empty?

        def present?
          !empty?
        end

        def presence
          self if present?
        end

        def least_specific
          first || Subdivision.new
        end

        def most_specific
          last || Subdivision.new
        end
      end

      class Postal < Result
        define_attr(:code)
      end

      class Traits < Result
        define_attr(:is_anonymous_proxy, aliases: :anonymous_proxy?)
        define_attr(:is_satellite_provider, aliases: :satellite_provider?)
      end

      # ------------------------------------------

      class Asn < Result
        def initialize(data = {})
          data ? super({ autonomous_system_network: data[:network] }.compact.merge(data)) : super()
        end

        define_attr(:autonomous_system_network, aliases: :network, export: true)
        define_attr(:autonomous_system_number, aliases: :number, export: true)
        define_attr(:autonomous_system_name, aliases: :name, export: true) { "AS#{number}" if number }
        define_attr(:autonomous_system_organization, aliases: :organization, export: true)
        define_attr(:autonomous_system_detailed, aliases: :detailed, export: true) { "AS#{number} #{organization}".strip if number }
      end

      class Geo < Result
        define_attr(:city, type: City, export: true)
        define_attr(:connection_type)
        define_attr(:continent, type: Continent, export: true)
        define_attr(:country, type: Country, export: true)
        define_attr(:location, type: Location)
        define_attr(:network)
        define_attr(:postal, type: Postal)
        define_attr(:registered_country, type: Country)
        define_attr(:represented_country, type: Country)
        define_attr(:subdivisions, type: Subdivisions)
        define_attr(:traits, type: Traits)

        define_attr(:accuracy_radius, memoize: false) { location.accuracy_radius }
        define_attr(:is_in_european_union, aliases: :in_european_union?, export: :in_european_union?, memoize: false) { country.is_in_european_union }
        define_attr(:latitude, memoize: false, export: true) { location.latitude }
        define_attr(:longitude, memoize: false, export: true) { location.longitude }
        define_attr(:metro_code, memoize: false) { location.metro_code }
        define_attr(:time_zone, memoize: false, aliases: :timezone, export: true) { location.time_zone }
        define_attr(:postal_code, aliases: :zip, export: true, memoize: false) { postal.code }

        define_attr(:detailed_parts, memoize: false) { [continent.code, country.name, city.name].compact }
        define_attr(:detailed, memoize: false) { detailed_parts.join(" / ") }
      end

      class GeoCountry < Geo; end
      class GeoCity < Geo; end

      # ------------------------------------------

      def initialize(data = {})
        super()
        merge!(data) if data
      end

      def inspect
        "#<#{self.class}:#{format("0x%x", object_id << 1)}: #{super}>"
      end

      alias_method :blank?, :empty?

      def present?
        !empty?
      end

      def presence
        self if present?
      end
    end
  end
end
