# frozen_string_literal: true

require "ipaddr"

module IParty
  class Address < IPAddr
    extend Forwardable

    attr_accessor :ipv6_significant

    def initialize *args, **kw
      self.ipv6_significant = kw.fetch(:significant, true)
      super(*args)

      raise IPAddr::AddressFamilyError, "unsupported address family" unless ipv4? || ipv6?
    end

    def type
      if ipv4?
        :ipv4
      elsif ipv6?
        :ipv6
      end
    end

    def size significant: ipv6_significant
      if ipv4?
        2**(32 - prefix)
      elsif ipv6?
        if significant || ipv4_mapped? || ipv4_compat?
          2**(128 - prefix)
        else
          2**[0, 128 - prefix - 64].max
        end
      end
    end

    def range? **kw
      size(**kw) > 1
    end

    # super but keeping significant option
    def to_range
      self.class.new(begin_addr, @family, significant: ipv6_significant)..self.class.new(end_addr, @family, significant: ipv6_significant)
    end

    def to_long_range **kw
      range = to_range
      [range.first.to_i(**kw), range.last.to_i(**kw)]
    end

    def to_significant
      self.class.new(@addr, @family, significant: true)
    end

    def to_insignificant
      self.class.new(@addr, @family, significant: false)
    end

    def to_cidr expand_v6: false, default_masks: false, significant: ipv6_significant
      cidr = expand_v6 ? to_string(significant:) : to_s(significant:)
      return cidr if !default_masks && !range?(significant: true) && !(ipv6? && !significant)

      if !significant && ipv6? && prefix > 64
        "#{cidr}/64"
      else
        "#{cidr}/#{prefix}"
      end
    end

    def to_i significant: ipv6_significant
      return super() if significant || !ipv6? || ipv4_mapped? || ipv4_compat? || prefix <= 64

      # drop upper 64 bits / host-identifier of ipv6
      (super() >> 64) & ((1 << 64) - 1)
    end

    def to_s significant: ipv6_significant
      return super() if significant || !ipv6? || ipv4_mapped? || ipv4_compat? || prefix <= 64

      mask(64).to_s(significant: true)
    end

    def to_string significant: ipv6_significant
      return super() if significant || !ipv6? || ipv4_mapped? || ipv4_compat? || prefix <= 64

      mask(64).to_string(significant: true)
    end

    def asn
      defined?(@_asn) ? @_asn : (@_asn = MaxMind.db(:ASN)&.lookup(self, result_class: MaxMind::Result::Asn) || MaxMind::Result::Asn.new)
    end

    def geo_country
      defined?(@_country) ? @_country : (@_country = MaxMind.db(:Country)&.lookup(self, result_class: MaxMind::Result::GeoCountry) || MaxMind::Result::GeoCountry.new)
    end

    def geo_city
      defined?(@_city) ? @_city : (@_city = MaxMind.db(:City)&.lookup(self, result_class: MaxMind::Result::GeoCity) || MaxMind::Result::GeoCity.new)
    end

    def geo
      defined?(@_geo) ? @_geo : (@_geo = geo_city.presence || geo_country.presence || MaxMind::Result::Geo.new)
    end

    def as_json
      {
        type: type,
        prefix: prefix,
        address: to_s,
        cidr: to_cidr,
        asn: asn.presence,
      }.merge(geo).compact
    end
  end
end
