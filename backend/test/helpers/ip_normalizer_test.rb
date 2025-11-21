require "test_helper"

class IpNormalizerTest < ActiveSupport::TestCase
  test "normalizes IPv6 addresses to network prefix" do
    # Same device with different interface identifiers
    ip1 = "2601:19b:1082:76b0:1bf0:57bd:2cdf:5156"
    ip2 = "2601:19b:1082:76b0:4171:4d6a:4900:60f9"
    
    normalized1 = IpNormalizer.normalize(ip1)
    normalized2 = IpNormalizer.normalize(ip2)
    
    assert_equal "2601:019b:1082:76b0", normalized1
    assert_equal "2601:019b:1082:76b0", normalized2
    assert_equal normalized1, normalized2, "Same network prefix should match"
  end

  test "handles IPv6 with leading zeros" do
    ip = "2001:0db8:85a3:0000:0000:8a2e:0370:7334"
    normalized = IpNormalizer.normalize(ip)
    assert_equal "2001:0db8:85a3:0000", normalized
  end

  test "handles IPv6 without leading zeros" do
    ip = "2001:db8:85a3:0:0:8a2e:370:7334"
    normalized = IpNormalizer.normalize(ip)
    assert_equal "2001:0db8:85a3:0000", normalized
  end

  test "handles compressed IPv6 with double colon" do
    ip = "2001:db8::8a2e:370:7334"
    normalized = IpNormalizer.normalize(ip)
    assert_equal "2001:0db8:0000:0000", normalized
  end

  test "handles IPv6 with double colon at start" do
    ip = "::1"
    normalized = IpNormalizer.normalize(ip)
    assert_equal "0000:0000:0000:0000", normalized
  end

  test "handles IPv6 with double colon at end" do
    ip = "2001:db8::"
    normalized = IpNormalizer.normalize(ip)
    assert_equal "2001:0db8:0000:0000", normalized
  end

  test "returns IPv4 addresses unchanged" do
    ip = "192.168.1.1"
    normalized = IpNormalizer.normalize(ip)
    assert_equal "192.168.1.1", normalized
  end

  test "returns nil for blank input" do
    assert_nil IpNormalizer.normalize(nil)
    assert_nil IpNormalizer.normalize("")
    assert_nil IpNormalizer.normalize("   ")
  end

  test "normalizes IPv6 to lowercase" do
    ip = "2001:0DB8:85A3:0000:0000:8A2E:0370:7334"
    normalized = IpNormalizer.normalize(ip)
    assert_equal "2001:0db8:85a3:0000", normalized
  end

  test "handles short IPv6 groups" do
    ip = "2001:db8:85a3:0:0:8a2e:370:7334"
    normalized = IpNormalizer.normalize(ip)
    # Should pad to 4 hex digits
    assert_equal "2001:0db8:85a3:0000", normalized
  end
end

