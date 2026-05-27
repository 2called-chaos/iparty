# frozen_string_literal: true

# within ~/.iparty/config.rb context

# iparty -d me
# iparty --dispatch me
# iparty --dispatch me short
def dispatch_me
  require "net/http"

  get_ip = proc do |url|
    Net::HTTP.get(URI(url))
  rescue Socket::ResolutionError
    formatter.colorize? ? c("SOCKET_ERROR", :red) : :SOCKET_ERROR
  rescue StandardError
    formatter.colorize? ? c("ERROR", :red) : :ERROR
  end

  if @argv.delete("short")
    out << formatter.format("my external ips") do
      onlyexcept_data!(
        ipv4: get_ip["https://api.ipify.org"],
        ipv6: get_ip["https://api6.ipify.org"],
      )
    end
  else
    @argv << get_ip["https://api.ipify.org"]
    @argv << get_ip["https://api6.ipify.org"]
    dispatch_info
  end
end
