require 'ipaddr'

module IpNormalizer
  # Normalize IP address for device identification
  # For IPv6: use only the network prefix (first 64 bits) to handle privacy extensions
  #   Example: 2601:19b:1082:76b0:1bf0:57bd:2cdf:5156 -> 2601:019b:1082:76b0
  # For IPv4: use the full IP address
  def self.normalize(ip_address)
    return nil if ip_address.blank?

    return ip_address unless ip_address.include?(':')

    normalize_ipv6(ip_address)
  end

  private

  def self.normalize_ipv6(ip_string)
    ip = IPAddr.new(ip_string)
    network_prefix = ip.mask(64)
    format_ipv6_groups(network_prefix)
  rescue IPAddr::InvalidAddressError
    nil
  end

  def self.format_ipv6_groups(ip)
    # Get the first 64 bits as an integer
    prefix_integer = ip.to_i >> 64
    
    # Convert to hex string (16 hex digits = 64 bits)
    hex_string = prefix_integer.to_s(16).rjust(16, '0')
    
    # Split into 4 groups of 4 hex digits each
    groups = hex_string.scan(/.{4}/)
    
    # Join with colons and ensure lowercase
    groups.join(':').downcase
  end
end

