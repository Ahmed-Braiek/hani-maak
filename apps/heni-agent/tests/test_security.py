import time
import unittest
from types import SimpleNamespace
from unittest.mock import patch

from app import security


class SecurityTests(unittest.TestCase):
    def test_voice_token_round_trip(self):
        with patch.object(security, "settings", SimpleNamespace(shared_secret="test-secret")):
            token = security.sign_voice_token({"sid": "s1", "patientId": "p1", "locale": "ar"}, ttl_seconds=60)
            claims = security.verify_voice_token(token)
            self.assertIsNotNone(claims)
            self.assertEqual(claims["patientId"], "p1")

    def test_expired_voice_token(self):
        with patch.object(security, "settings", SimpleNamespace(shared_secret="test-secret")):
            token = security.sign_voice_token({"sid": "s1", "patientId": "p1", "exp": int(time.time()) - 2})
            self.assertIsNone(security.verify_voice_token(token))


if __name__ == "__main__":
    unittest.main()
