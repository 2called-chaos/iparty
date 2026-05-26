# frozen_string_literal: true

module IParty
  class MaxMind
    # A fast read-access reader for MaxMindDB (mmdb) files. Reads the database into memory.
    # This creates a higher memory overhead and slower init phase but faster lookup times.
    class EagerReader
      def initialize path
        @data = File.binread(path)
      end

      def [] pos, length = 1
        raise IOError, "closed stream" unless @data

        @data.slice(pos, length)
      end

      def rindex search
        raise IOError, "closed stream" unless @data

        @data.rindex(search)
      end

      def close
        @data = nil
      end

      def closed?
        @data.nil?
      end
    end
  end
end
