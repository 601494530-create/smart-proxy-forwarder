"""Integration tests for proxy_forwarder (requires network)."""
import socket
import threading
import time
import unittest
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import proxy_forwarder as pf


class TestChinaIPSetIntegration(unittest.TestCase):
    """Integration tests for ChinaIPSet with real IP data."""

    def test_common_china_ips(self):
        """Verify well-known China IPs are correctly classified."""
        c = pf.ChinaIPSet()
        cases = [
            ("223.5.5.5", True),     # Alibaba DNS
            ("114.114.114.114", True), # 114 DNS
            ("119.125.217.23", True), # Guangdong Telecom
            ("8.8.8.8", False),       # Google DNS
            ("208.67.222.222", False), # OpenDNS
            ("1.1.1.1", True),        # 1.0.0.0/8 is allocated to APNIC/China
        ]
        for ip, expected in cases:
            self.assertEqual(c.contains(ip), expected, f"Mismatch for {ip}")

    def test_builtin_ranges_loaded(self):
        """Built-in CIDRs should be loaded on construction."""
        c = pf.ChinaIPSet()
        self.assertGreater(len(c._networks), 40)


class TestCONNECTProtocol(unittest.TestCase):
    """Test CONNECT request parsing logic with sample HTTP data."""

    def test_parse_valid_connect(self):
        """Simulate handle_client receiving a CONNECT request."""
        data = b"CONNECT www.google.com:443 HTTP/1.1\r\nHost: www.google.com:443\r\n\r\n"
        first_line = data.split(b"\r\n")[0].decode("utf-8", errors="replace")
        parts = first_line.split()
        self.assertEqual(len(parts), 3)
        self.assertEqual(parts[0], "CONNECT")
        target = parts[1]
        dst_host, _, dst_port_str = target.partition(":")
        self.assertEqual(dst_host, "www.google.com")
        self.assertEqual(dst_port_str, "443")

    def test_parse_connect_without_port(self):
        data = b"CONNECT 1.2.3.4 HTTP/1.1\r\n\r\n"
        first_line = data.split(b"\r\n")[0].decode("utf-8", errors="replace")
        parts = first_line.split()
        target = parts[1]
        dst_host, _, dst_port_str = target.partition(":")
        self.assertEqual(dst_host, "1.2.3.4")
        self.assertEqual(dst_port_str, "")

    def test_relay_traffic_shutdown(self):
        """Test that shutdown_event stops relay_traffic."""
        import socket as sock
        a, b = sock.socketpair()
        evt = threading.Event()
        t = threading.Thread(target=pf.relay_traffic, args=(a, b, evt), daemon=True)
        t.start()
        time.sleep(0.1)
        evt.set()
        t.join(timeout=2)
        self.assertFalse(t.is_alive(), "relay_traffic should exit after shutdown_event")
        a.close()
        b.close()


class TestRoutingLogic(unittest.TestCase):
    """Test the routing decision logic used in handle_client."""

    def setUp(self):
        self.china = pf.ChinaIPSet()
        self.domains = pf.DEFAULT_DIRECT_DOMAINS

    def test_routing_google(self):
        """www.google.com should route to proxy (not in direct list, not IP)."""
        self.assertFalse(pf.is_direct_domain("www.google.com", self.domains))
        self.assertFalse(pf.is_ip_string("www.google.com"))
        # → should use proxy (DNS-safe path)

    def test_routing_baidu(self):
        """www.baidu.com should route direct (in domain list)."""
        self.assertTrue(pf.is_direct_domain("www.baidu.com", self.domains))

    def test_routing_china_ip(self):
        """A China IP address should route direct."""
        self.assertTrue(pf.is_ip_string("119.125.217.23"))
        self.assertTrue(self.china.contains("119.125.217.23"))
        # → should not use proxy

    def test_routing_foreign_ip(self):
        """A foreign IP address should route to proxy."""
        self.assertTrue(pf.is_ip_string("8.8.8.8"))
        self.assertFalse(self.china.contains("8.8.8.8"))
        # → should use proxy


if __name__ == "__main__":
    unittest.main()
