# frozen_string_literal: true

require "ipaddr"

module IParty
  class Address < IPAddr
    extend Forwardable

    attr_accessor :ipv6_significant

    def initialize *args, **kw
      self.ipv6_significant = kw.fetch(:significant, true)
      super(*args)
      self.ipv6_significant = true if force_significant?

      raise IPAddr::AddressFamilyError, "unsupported address family" unless ipv4? || ipv6?
    end

    def force_significant?
      @family == Socket::AF_INET6 && @addr == 1
    end

    def type
      if @family == Socket::AF_INET
        :ipv4
      elsif @family == Socket::AF_INET6
        :ipv6
      end
    end

    def size significant: ipv6_significant
      if ipv4?
        2**(32 - prefix)
      elsif ipv6?
        if force_significant? || significant || ipv4_mapped? || ipv4_compat?
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

    def to_cidr expand_v6: false, default_masks: false, netmask: false, significant: ipv6_significant
      significant = true if force_significant?
      cidr = expand_v6 ? to_string(significant:) : to_s(significant:)
      return cidr if !default_masks && !range?(significant: true) && !(ipv6? && !significant)

      mp = prefix
      if @family == Socket::AF_INET
        masklen = 32 - mp
        mask_addr = ((IN4MASK >> masklen) << masklen)
      else
        mp = 64 if !significant && mp > 64
        masklen = 128 - mp
        mask_addr = ((IN6MASK >> masklen) << masklen)
      end

      "#{cidr}/#{netmask ? _to_string(mask_addr) : mp}"
    end

    def prefix significant: ipv6_significant
      return super() if force_significant? || significant || !ipv6? || ipv4_mapped? || ipv4_compat? || super() <= 64

      64
    end

    def to_i significant: ipv6_significant
      return super() if force_significant? || significant || !ipv6? || ipv4_mapped? || ipv4_compat? || prefix(significant: true) <= 64

      # drop upper 64 bits / host-identifier of ipv6
      (super() >> 64) & ((1 << 64) - 1)
    end

    def to_s significant: ipv6_significant
      return super() if force_significant? || significant || !ipv6? || ipv4_mapped? || ipv4_compat? || prefix(significant: true) <= 64

      mask(64).to_s(significant: true)
    end

    def to_string significant: ipv6_significant
      return super() if force_significant? || significant || !ipv6? || ipv4_mapped? || ipv4_compat? || prefix(significant: true) <= 64

      mask(64).to_string(significant: true)
    end

    def asn
      defined?(@_asn) ? @_asn : (@_asn = MaxMind.lookup(:ASN, self, result_class: MaxMind::Result::Asn) || MaxMind::Result::Asn.new)
    end

    def geo_country
      defined?(@_country) ? @_country : (@_country = MaxMind.lookup(:Country, self, result_class: MaxMind::Result::GeoCountry) || MaxMind::Result::GeoCountry.new)
    end

    def geo_city
      defined?(@_city) ? @_city : (@_city = MaxMind.lookup(:City, self, result_class: MaxMind::Result::GeoCity) || MaxMind::Result::GeoCity.new)
    end

    def geo
      defined?(@_geo) ? @_geo : (@_geo = geo_city.presence || geo_country.presence || MaxMind::Result::Geo.new)
    end

    def annotations
      return @_annotations if defined?(@_annotations)

      result = {}
      IParty.config.annotations&.each do |ipp, adata|
        next unless ipp.include?(self)

        result.merge!(adata.merge(tags: result.fetch(:tags, []) | adata.fetch(:tags, [])))
      end

      @_annotations = result.empty? ? nil : result
    end

    def tag? tag
      return false unless tags = annotations&.fetch(:tags, nil)

      tags.include?(tag)
    end

    def as_json
      {
        type: type,
        prefix: prefix,
        address: to_s,
        cidr: to_cidr,
        network: nil,
        annotations: annotations,
      }.merge(asn.merge(network: nil), geo).compact
    end
  end
end
