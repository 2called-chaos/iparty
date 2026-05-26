# frozen_string_literal: true

require_relative "lazy_reader"
require_relative "eager_reader"
require_relative "result"

module IParty
  class MaxMind
    class Database
      class Error < IParty::Error; end
      class InvalidFileFormatError < Error; end

      METADATA_BEGIN_MARKER = "#{[0xAB, 0xCD, 0xEF].pack("C*")}MaxMind.com".encode("ascii-8bit", "ascii-8bit").freeze
      DATA_SECTION_SEPARATOR_SIZE = 16
      SIZE_BASE_VALUES = [0, 29, 285, 65_821].freeze
      POINTER_BASE_VALUES = [0, 0, 2048, 526_336].freeze

      attr_reader :metadata

      def initialize(path, reader: EagerReader)
        @path = path
        @data = reader.new(path)

        pos = @data.rindex(METADATA_BEGIN_MARKER) || raise(InvalidFileFormatError, "invalid file format")
        pos += METADATA_BEGIN_MARKER.size
        @metadata = decode(0, pos)[1]

        @ip_version = @metadata[:ip_version]
        @start_idx = @ip_version == 4 ? 96 : 0
        @node_count = @metadata[:node_count]
        @node_byte_size = @metadata[:record_size] * 2 / 8
        @search_tree_size = @node_count * @node_byte_size
        @data_section_start = @search_tree_size + DATA_SECTION_SEPARATOR_SIZE
      end

      def close
        @data.close
      end

      def closed?
        @data.closed?
      end

      def inspect
        "#<#{self.class}:#{format("0x%x", object_id << 1)}: @path:#{@path} @metadata:#{@metadata}>"
      end

      def lookup(addr, result_class: Result::Geo)
        addr = IPAddr.new(addr) unless addr.is_a?(IPAddr)
        addr = IParty.config.local_ip_alias if IParty.config.local_ip_alias && addr.loopback?
        addr = IPAddr.new(addr) unless addr.is_a?(IPAddr)
        compat_addr = addr.ipv4? ? addr.ipv4_compat : addr
        long = compat_addr.is_a?(IParty::Address) ? compat_addr.to_i(significant: true) : compat_addr.to_i
        node_no = 0

        (@start_idx...128).each do |i|
          flag = (long >> (127 - i)) & 1
          next_node_no = read_record(node_no, flag)

          if next_node_no == 0
            raise(InvalidFileFormatError, "invalid file format")
          elsif next_node_no >= @node_count
            pos = (next_node_no - @node_count) - DATA_SECTION_SEPARATOR_SIZE
            result           = decode(@data_section_start, pos)[1]
            result[:network] = if !result.empty?
              cidr_from_long(long, i)
            elsif addr.loopback?
              @family == Socket::AF_INET6 ? "::1/128" : "127.0.0.0/8"
            end
            return result_class.new(result)
          else
            node_no = next_node_no
          end
        end

        raise(InvalidFileFormatError, "invalid file format")
      end

      def cidr_from_long(long, net)
        addr = IPAddr.new(long, long > (2**32) - 1 ? Socket::AF_INET6 : Socket::AF_INET)
        subnet_size = addr.ipv4? ? net - 96 + 1 : net + 1
        subnet      = IPAddr.new("#{addr}/#{subnet_size}")

        "#{subnet}/#{subnet_size}"
      end

      def read_record(node_no, flag)
        rec_byte_size = @node_byte_size / 2
        pos = @node_byte_size * node_no
        middle = @data[pos + rec_byte_size].ord if @node_byte_size.odd?

        if flag == 0 # left
          val = read_value(pos, 0, rec_byte_size)
          val += ((middle & 0xf0) << 20) if middle
        else # right
          val = read_value(pos + @node_byte_size - rec_byte_size, 0, rec_byte_size)
          val += ((middle & 0xf) << 24) if middle
        end

        val
      end

      def read_value(base_pos, pos, size)
        bytes = @data[base_pos + pos, size].unpack("C*")
        bytes.inject(0){|r, v| (r << 8) + v }
      end

      # rubocop:disable Metrics/CyclomaticComplexity -- we could reduce this, sacrificing the neat overview
      def decode base_pos, pos
        ctrl = @data[base_pos + pos].ord
        pos += 1
        type = ctrl >> 5

        if type == 1 # pointer
          decode_pointer(base_pos, pos, ctrl)
        else
          if type == 0 # extended type
            type = 7 + @data[base_pos + pos].ord
            pos += 1
          end

          size = ctrl & 0x1f
          if size >= 29
            byte_size = size - 29 + 1
            val = read_value(base_pos, pos, byte_size)
            pos += byte_size
            size = val + SIZE_BASE_VALUES[byte_size]
          end

          # rubocop:disable Lint/DuplicateBranch -- readable order is more important
          case type
          when 2 # utf8
            decode_utf8(base_pos, pos, size)
          when 3 # double
            decode_double(base_pos, pos, size)
          when 4 # bytes
            decode_bytes(base_pos, pos, size)
          when 5 # unsigned 16-bit int
            decode_uint(base_pos, pos, size)
          when 6 # unsigned 32-bit int
            decode_uint(base_pos, pos, size)
          when 7 # map
            decode_map(base_pos, pos, size)
          when 8 # signed 32-bit int
            decode_int(base_pos, pos, size)
          when 9 # unsigned 64-bit int
            decode_uint(base_pos, pos, size)
          when 10 # unsigned 128-bit int
            decode_uint(base_pos, pos, size)
          when 11 # array
            decode_array(base_pos, pos, size)
          when 12 # (deprecated) data cache container
            raise "TODO: (deprecated) data cache container format"
          when 13 # (deprecated) end marker
            [pos, nil]
          when 14 # boolean
            [pos, size != 0]
          when 15 # float
            decode_float(base_pos, pos, size)
          end
          # rubocop:enable Lint/DuplicateBranch
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def decode_double base_pos, pos, size
        [pos + size, @data[base_pos + pos, size].unpack1("G")]
      end

      def decode_bytes base_pos, pos, size
        [pos + size, @data[base_pos + pos, size]]
      end

      def decode_int base_pos, pos, size
        v1 = @data[base_pos + pos, size].unpack1("N")
        bits = size * 8
        [pos + size, (v1 & ~(1 << bits)) - (v1 & (1 << bits))]
      end

      def decode_uint base_pos, pos, size
        [pos + size, read_value(base_pos, pos, size)]
      end

      def decode_float base_pos, pos, size
        [pos + size, @data[base_pos + pos, size].unpack1("g")]
      end

      def decode_utf8 base_pos, pos, size
        [pos + size, @data[base_pos + pos, size].encode("utf-8", "utf-8")]
      end

      def decode_pointer base_pos, pos, ctrl
        size = ((ctrl >> 3) & 0x3) + 1
        v1 = ctrl & 0x7
        v2 = read_value(base_pos, pos, size)

        pointer = (v1 << (8 * size)) + v2 + POINTER_BASE_VALUES[size]
        [pos + size, decode(base_pos, pointer)[1]]
      end

      def decode_array base_pos, pos, size
        ary = Array.new(size) do
          pos, v = decode(base_pos, pos)
          v
        end
        [pos, ary]
      end

      def decode_map base_pos, pos, size
        map = {}
        size.times do
          pos, k = decode(base_pos, pos)
          pos, v = decode(base_pos, pos)
          map[k.to_sym] = v
        end
        [pos, map]
      end
    end
  end
end
