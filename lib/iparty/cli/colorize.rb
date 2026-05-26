# frozen_string_literal: true

module IParty
  module CLI
    module Colorize
      class UnknownColorError < ArgumentError; end

      COLORMAP = {
        black: 30,
        gray: 30,
        red: 31,
        green: 32,
        yellow: 33,
        blue: 34,
        magenta: 35,
        cyan: 36,
        white: 37,
      }.freeze

      def colorize str, color = :yellow
        ccode = COLORMAP[color.to_sym] || raise(UnknownColorError, "unknown color `#{color}'")
        @opts[:colorize] ? "\e[#{ccode}m#{str}\e[0m" : str.to_s
      end
      alias_method :c, :colorize

      def decolorize str
        str.to_s.gsub(/\e\[.*?(\d)+m/, "")
      end

      def with_color *args
        color_was = @opts[:colorize]
        @opts[:colorize] = args.fetch(0, true)
        yield
      ensure
        @opts[:colorize] = color_was
      end
    end
  end
end
